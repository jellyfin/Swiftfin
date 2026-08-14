//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

@MainActor
class CastMediaPlayerProxy: MediaPlayerProxy, MediaPlayerAudioTrackConfigurable, MediaPlayerSubtitleTrackConfigurable {

    let isBuffering: PublishedBox<Bool> = .init(initialValue: false)

    @Published
    private(set) var hasStarted: Bool = false
    @Published
    private(set) var isEnded: Bool = false
    @Published
    private(set) var isMuted: Bool = false
    @Published
    private(set) var isPaused: Bool = false
    @Published
    private(set) var nowPlayingItem: BaseItemDto?
    @Published
    private(set) var queueCount: Int = 0
    @Published
    private(set) var queueIndex: Int?
    @Published
    private(set) var queueItems: [BaseItemDto] = []
    @Published
    private(set) var seconds: Duration = .zero
    @Published
    private(set) var selectedAudioStreamIndex: Int = -1
    @Published
    private(set) var selectedSubtitleStreamIndex: Int = -1

    weak var manager: MediaPlayerManager?

    // suspended while a menu is open so its contents don't
    // change underneath, bounded so sync can't be lost
    var isSyncSuspended: Bool = false {
        didSet {
            syncSuspendedSince = isSyncSuspended ? .now : nil
        }
    }

    /// The item to cast, or `nil` when controlling whatever the session plays
    let item: BaseItemDto?
    let session: SessionViewModel

    private var cancellables = Set<AnyCancellable>()
    private var idleSince: Date?
    private var isStopping = false
    private var itemChangedAt: Date = .distantPast
    private var previousItemID: String?
    private var queueItemIDs: [String] = []
    private var startTimeoutTask: Task<Void, Never>?
    private var suppressSyncUntil: Date = .distantPast
    private var syncSuspendedSince: Date?
    private var tickerTask: Task<Void, Never>?

    private var runtime: Duration? {
        nowPlayingItem?.runtime ?? item?.runtime
    }

    private var isSuspended: Bool {
        guard let syncSuspendedSince else { return false }
        return Date.now.timeIntervalSince(syncSuspendedSince) < 15
    }

    static func isPlaying(item: BaseItemDto, in session: SessionInfoDto) -> Bool {
        guard let nowPlayingItem = session.nowPlayingItem else { return false }

        if nowPlayingItem.id == item.id { return true }

        let itemChannelID = item.channelID ?? (item.isLiveStream ? item.id : nil)
        let nowPlayingChannelID = nowPlayingItem.channelID ?? (nowPlayingItem.isLiveStream ? nowPlayingItem.id : nil)

        guard let itemChannelID, let nowPlayingChannelID else { return false }

        return itemChannelID == nowPlayingChannelID
    }

    init(item: BaseItemDto?, session: SessionViewModel) {
        self.item = item
        self.session = session

        let isAttaching = item.map { Self.isPlaying(item: $0, in: session.session) } ?? true

        if isAttaching, let playState = session.session.playState, session.session.nowPlayingItem != nil {
            hasStarted = true
            nowPlayingItem = session.session.nowPlayingItem
            seconds = playState.position ?? item?.startSeconds ?? .zero
            isPaused = playState.isPaused ?? false
            isMuted = playState.isMuted ?? false
            selectedAudioStreamIndex = playState.audioStreamIndex ?? -1
            selectedSubtitleStreamIndex = playState.subtitleStreamIndex ?? -1
            updateQueueCount(session.session)
        } else if let item {
            isBuffering.value = true
            seconds = item.startSeconds ?? .zero
            suppressSyncUntil = Date.now.addingTimeInterval(3)
            startStartTimeout()
        }

        session.$session
            .sink { [weak self] session in
                self?.handle(session)
            }
            .store(in: &cancellables)

        startTicker()
        fetchFullNowPlayingItem()
    }

    func play() {
        isPaused = false
        markLocalCommand()
        session.sendPlaystateCommand(command: .unpause, seekPositionTicks: nil)
    }

    func pause() {
        isPaused = true
        markLocalCommand()
        session.sendPlaystateCommand(command: .pause, seekPositionTicks: nil)
    }

    func stop() {
        clearNowPlaying()
        isStopping = true
        idleSince = .now

        // the session is only accurate once the command has landed
        Task {
            await session.sendPlaystateCommand(command: .stop, seekPositionTicks: nil)
        }
    }

    func jumpForward(_ seconds: Duration) {
        setSeconds(self.seconds + seconds)
    }

    func jumpBackward(_ seconds: Duration) {
        setSeconds(self.seconds - seconds)
    }

    func setRate(_ rate: Float) {}

    func nextItem() {
        markLocalCommand()
        session.sendPlaystateCommand(command: .nextTrack, seekPositionTicks: nil)
    }

    func previousItem() {
        markLocalCommand()
        session.sendPlaystateCommand(command: .previousTrack, seekPositionTicks: nil)
    }

    // there is no jump-to-index command, so the queue is replayed
    // from the selected item to keep the remaining queue intact
    func playQueueItem(_ item: BaseItemDto) {
        guard let index = queueItemIDs.firstIndex(of: item.id ?? "") else { return }

        markLocalCommand()

        // the chosen item is known, don't wait on the session to confirm it
        previousItemID = nowPlayingItem?.id
        itemChangedAt = .now
        nowPlayingItem = item
        seconds = .zero
        fetchFullNowPlayingItem()

        startRemoteSession(
            itemIDs: queueItemIDs,
            startPositionTicks: nil,
            mediaSourceID: nil,
            startIndex: index
        )
    }

    func setMediaSource(_ mediaSource: MediaSourceInfo) {
        guard let itemID = nowPlayingItem?.id else { return }

        // without a known queue position the queue cannot be
        // replayed without starting from a different item
        let canReplayQueue = queueItemIDs.isNotEmpty && queueIndex != nil

        markLocalCommand()
        startRemoteSession(
            itemIDs: canReplayQueue ? queueItemIDs : [itemID],
            startPositionTicks: seconds.ticks,
            mediaSourceID: mediaSource.id,
            startIndex: canReplayQueue ? queueIndex : nil
        )
    }

    // the session still reports the previous item until the command lands
    private func startRemoteSession(
        itemIDs: [String],
        startPositionTicks: Int?,
        mediaSourceID: String?,
        startIndex: Int?
    ) {
        Task {
            await session.remotePlaybackSession(
                command: .playNow,
                itemIDs: itemIDs,
                startPositionTicks: startPositionTicks,
                mediaSourceID: mediaSourceID,
                audioStreamIndex: nil,
                subtitleStreamIndex: nil,
                startIndex: startIndex
            )

            await session.refresh()
        }
    }

    func toggleMute() {
        isMuted.toggle()
        markLocalCommand()
        session.sendGeneralCommand(.toggleMute)
    }

    func setAudioStream(_ stream: MediaStream) {
        guard let index = stream.index else { return }

        selectedAudioStreamIndex = index
        markLocalCommand()
        session.sendFullGeneralCommand(
            GeneralCommand(
                arguments: ["Index": "\(index)"],
                name: .setAudioStreamIndex
            )
        )
    }

    func setSubtitleStream(_ stream: MediaStream) {
        let index = stream.index ?? -1

        selectedSubtitleStreamIndex = index
        markLocalCommand()
        session.sendFullGeneralCommand(
            GeneralCommand(
                arguments: ["Index": "\(index)"],
                name: .setSubtitleStreamIndex
            )
        )
    }

    func setSeconds(_ seconds: Duration) {
        var newSeconds = max(.zero, seconds)
        if let runtime {
            newSeconds = min(newSeconds, runtime)
        }

        self.seconds = newSeconds
        markLocalCommand()
        session.sendPlaystateCommand(
            command: .seek,
            seekPositionTicks: newSeconds.ticks
        )
    }

    private func isStillPlaying(_ session: SessionInfoDto) -> Bool {
        guard let item, !hasStarted else {
            return session.nowPlayingItem != nil
        }

        return Self.isPlaying(item: item, in: session)
    }

    private func handle(_ session: SessionInfoDto) {
        guard !isSuspended else { return }

        // frames can still report the stopped item until the server catches up
        if isStopping {
            guard session.nowPlayingItem == nil else { return }
            isStopping = false
        }

        guard isStillPlaying(session) else {
            if idleSince == nil {
                idleSince = .now
            }

            return
        }

        if !hasStarted {
            hasStarted = true
            isBuffering.value = false
            startTimeoutTask?.cancel()
        }

        idleSince = nil
        updateNowPlayingItem(session.nowPlayingItem)
        updateQueueCount(session)

        // Socket updates can lag behind. Don't let stale state revert them.
        guard Date.now >= suppressSyncUntil, let playState = session.playState else { return }

        isPaused = playState.isPaused ?? false
        isMuted = playState.isMuted ?? false
        selectedAudioStreamIndex = playState.audioStreamIndex ?? selectedAudioStreamIndex
        selectedSubtitleStreamIndex = playState.subtitleStreamIndex ?? selectedSubtitleStreamIndex

        if let remotePosition = playState.position {
            let drift = abs(remotePosition.seconds - seconds.seconds)

            if isPaused || drift > 2 {
                seconds = remotePosition
            }
        }
    }

    private func updateNowPlayingItem(_ incoming: BaseItemDto?) {
        guard let incoming, let incomingID = incoming.id else { return }

        // the session reports a slimmer item than the fetched one
        if incomingID == nowPlayingItem?.id {
            return
        }

        // transitions bounce back to the item just left for a frame or two
        if incomingID == previousItemID, Date.now.timeIntervalSince(itemChangedAt) < 5 {
            return
        }

        let isReplacing = nowPlayingItem != nil

        previousItemID = nowPlayingItem?.id
        itemChangedAt = .now
        nowPlayingItem = incoming

        if isReplacing {
            // the previous item's position is meaningless for the new one
            seconds = .zero
            suppressSyncUntil = .distantPast
        }

        fetchFullNowPlayingItem()
    }

    private func clearNowPlaying() {
        guard nowPlayingItem != nil else { return }

        isPaused = true
        previousItemID = nil
        nowPlayingItem = nil
        queueCount = 0
        queueIndex = nil
        queueItemIDs = []
        queueItems = []
        seconds = .zero
    }

    // sessions report items without media sources
    private func fetchFullNowPlayingItem() {
        Task {
            guard let userSession = session.userSession,
                  let item = nowPlayingItem,
                  item.mediaSources == nil,
                  let fullItem = try? await item.getFullItem(userSession: userSession),
                  fullItem.id == nowPlayingItem?.id
            else {
                return
            }

            nowPlayingItem = fullItem
        }
    }

    private func updateQueueCount(_ session: SessionInfoDto) {
        guard let queue = session.nowPlayingQueue, queue.isNotEmpty else { return }

        queueCount = queue.count
        queueIndex = queue.firstIndex { $0.playlistItemID == session.playlistItemID }
            ?? queue.firstIndex { $0.id == session.nowPlayingItem?.id }

        let ids = queue.compactMap(\.id)
        guard ids != queueItemIDs else { return }

        queueItemIDs = ids
        fetchQueueItems(ids: ids)
    }

    private func fetchQueueItems(ids: [String]) {
        Task {
            guard let userID = session.userSession?.user.id else { return }

            var parameters = Paths.GetItemsParameters()
            parameters.fields = .MinimumFields
            parameters.ids = ids
            parameters.userID = userID

            let request = Paths.getItems(parameters: parameters)
            guard let items = try? await session.send(request).value.items else { return }

            queueItems = ids.compactMap { id in
                items.first { $0.id == id }
            }
        }
    }

    private func end() {
        isEnded = true
        startTimeoutTask?.cancel()
        startTimeoutTask = nil
        tickerTask?.cancel()
        tickerTask = nil
    }

    private func markLocalCommand() {
        suppressSyncUntil = Date.now.addingTimeInterval(8)
    }

    private func startTicker() {
        tickerTask?.cancel()
        tickerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))

                guard !Task.isCancelled, let self else { return }
                self.tick()
            }
        }
    }

    private func tick() {
        // publishing here would dismiss an open menu
        guard !isSuspended else { return }

        // the session can stop reporting entirely, so idle is timed
        // here instead of waiting on another frame to arrive
        if let idleSince {
            let idleSeconds = Date.now.timeIntervalSince(idleSince)

            // queue changeovers can idle the session while the next
            // item's playback spins up, only act after a sustained gap
            if idleSeconds >= 5 {
                clearNowPlaying()
            }

            // a remote without an item has nothing to end
            if idleSeconds >= 30, hasStarted, item != nil {
                end()
            }

            return
        }

        guard hasStarted, !isPaused, !isEnded else { return }

        var newSeconds = seconds + .seconds(1)
        if let runtime {
            newSeconds = min(newSeconds, runtime)
        }

        seconds = newSeconds
    }

    private func startStartTimeout() {
        startTimeoutTask?.cancel()
        startTimeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(30))

            guard !Task.isCancelled, let self, !self.hasStarted else { return }
            self.end()
        }
    }
}
