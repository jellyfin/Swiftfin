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
class CastMediaPlayerProxy: RemoteMediaPlayerProxy,
    MediaPlayerAudioTrackConfigurable,
    MediaPlayerSubtitleTrackConfigurable,
    MediaPlayerQueueConfigurable,
    MediaPlayerVolumeConfigurable
{

    let isBuffering: PublishedBox<Bool> = .init(initialValue: false)

    @Published
    private(set) var hasStarted: Bool = false
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
    @Published
    private(set) var volumeLevel: Int = 100

    weak var manager: MediaPlayerManager?

    var isSyncSuspended: Bool = false {
        didSet {
            syncSuspendedSince = isSyncSuspended ? .now : nil
        }
    }

    let item: BaseItemDto?
    let session: SessionViewModel

    private var cancellables = Set<AnyCancellable>()
    private var idleSince: Date?
    private var isStopping = false
    private var itemChangedAt: Date = .distantPast
    private var previousItemID: String?
    private var queueItemIDs: [String] = []
    private var suppressSyncUntil: Date = .distantPast
    private var syncSuspendedSince: Date?
    private var tickerTask: Task<Void, Never>?

    var activeItem: BaseItemDto? {
        nowPlayingItem ?? (hasStarted ? nil : item)
    }

    private var isSuspended: Bool {
        guard let syncSuspendedSince else { return false }
        return Date.now.timeIntervalSince(syncSuspendedSince) < 15
    }

    private var runtime: Duration? {
        nowPlayingItem?.runtime ?? item?.runtime
    }

    init(item: BaseItemDto?, session: SessionViewModel) {
        self.item = item
        self.session = session

        let isAttaching = item.map { session.session.isPlaying(item: $0) } ?? true

        if isAttaching, let playState = session.session.playState, session.session.nowPlayingItem != nil {
            hasStarted = true
            nowPlayingItem = session.session.nowPlayingItem
            seconds = playState.position ?? item?.startSeconds ?? .zero
            isPaused = playState.isPaused ?? false
            isMuted = playState.isMuted ?? false
            selectedAudioStreamIndex = playState.audioStreamIndex ?? -1
            selectedSubtitleStreamIndex = playState.subtitleStreamIndex ?? -1
            volumeLevel = playState.volumeLevel ?? 100
            updateQueue(from: session.session)
        } else if let item {
            seconds = item.startSeconds ?? .zero
            suppressSyncUntil = Date.now.addingTimeInterval(3)
        }

        session.$session
            .sink { [weak self] session in
                self?.handle(session)
            }
            .store(in: &cancellables)

        startTicker()
        fetchFullNowPlayingItem()
    }

    deinit {
        tickerTask?.cancel()
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

    func toggleMute() {
        isMuted.toggle()
        markLocalCommand()
        session.sendGeneralCommand(.toggleMute)
    }

    func setMaxBitrate(_ bitrate: PlaybackBitrate) {
        session.sendFullGeneralCommand(
            GeneralCommand(
                arguments: ["Bitrate": "\(bitrate.rawValue)"],
                name: .setMaxStreamingBitrate
            )
        )
    }

    func setVolume(_ level: Int) {
        volumeLevel = level
        markLocalCommand()
        session.sendFullGeneralCommand(
            GeneralCommand(
                arguments: ["Volume": "\(level)"],
                name: .setVolume
            )
        )
    }

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

        let canReplayQueue = queueItemIDs.isNotEmpty && queueIndex != nil

        markLocalCommand()
        startRemoteSession(
            itemIDs: canReplayQueue ? queueItemIDs : [itemID],
            startPositionTicks: seconds.ticks,
            mediaSourceID: mediaSource.id,
            startIndex: canReplayQueue ? queueIndex : nil
        )
    }

    func refreshNowPlayingItem() async {
        guard let userSession = session.userSession,
              let item = nowPlayingItem,
              let fullItem = try? await item.getFullItem(userSession: userSession),
              fullItem.id == nowPlayingItem?.id
        else {
            return
        }

        nowPlayingItem = fullItem
    }
}

// MARK: - Session Sync

// The target session takes the place of a local player, with
// its socket frames standing in for player events. Commands are
// applied optimistically and stale frames suppressed until the
// session reports the result.
private extension CastMediaPlayerProxy {

    func markLocalCommand() {
        suppressSyncUntil = Date.now.addingTimeInterval(8)
    }

    func startRemoteSession(
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

    func isStillPlaying(_ session: SessionInfoDto) -> Bool {
        guard let item, !hasStarted else {
            return session.nowPlayingItem != nil
        }

        return session.isPlaying(item: item)
    }

    func handle(_ session: SessionInfoDto) {
        guard !isSuspended else { return }

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
        }

        idleSince = nil
        updateNowPlayingItem(session.nowPlayingItem)
        updateQueue(from: session)

        guard Date.now >= suppressSyncUntil, let playState = session.playState else { return }

        isPaused = playState.isPaused ?? false
        isMuted = playState.isMuted ?? false
        selectedAudioStreamIndex = playState.audioStreamIndex ?? selectedAudioStreamIndex
        selectedSubtitleStreamIndex = playState.subtitleStreamIndex ?? selectedSubtitleStreamIndex
        volumeLevel = playState.volumeLevel ?? volumeLevel

        if let remotePosition = playState.position {
            let drift = abs(remotePosition.seconds - seconds.seconds)

            if isPaused || drift > 2 {
                seconds = remotePosition
            }
        }
    }

    func updateNowPlayingItem(_ incoming: BaseItemDto?) {
        guard let incoming, let incomingID = incoming.id else { return }

        if incomingID == nowPlayingItem?.id {
            return
        }

        if incomingID == previousItemID, Date.now.timeIntervalSince(itemChangedAt) < 5 {
            return
        }

        let isReplacing = nowPlayingItem != nil

        previousItemID = nowPlayingItem?.id
        itemChangedAt = .now
        nowPlayingItem = incoming

        if isReplacing {
            seconds = .zero
            suppressSyncUntil = .distantPast

            if !queueItemIDs.contains(incomingID) {
                clearQueue()
            }
        }

        fetchFullNowPlayingItem()
    }

    func updateQueue(from session: SessionInfoDto) {
        guard let queue = session.nowPlayingQueue, queue.isNotEmpty else { return }

        queueCount = queue.count
        queueIndex = queue.firstIndex { $0.playlistItemID == session.playlistItemID }
            ?? queue.firstIndex { $0.id == session.nowPlayingItem?.id }

        let ids = queue.compactMap(\.id)
        guard ids != queueItemIDs else { return }

        queueItemIDs = ids
        fetchQueueItems(ids: ids)
    }

    func clearNowPlaying() {
        guard nowPlayingItem != nil else { return }

        isPaused = true
        previousItemID = nil
        nowPlayingItem = nil
        seconds = .zero
        clearQueue()
    }

    func clearQueue() {
        queueCount = 0
        queueIndex = nil
        queueItemIDs = []
        queueItems = []
    }

    func fetchFullNowPlayingItem() {
        Task {
            guard nowPlayingItem?.mediaSources == nil else { return }
            await refreshNowPlayingItem()
        }
    }

    func fetchQueueItems(ids: [String]) {
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

    func startTicker() {
        tickerTask?.cancel()
        tickerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))

                guard !Task.isCancelled, let self else { return }
                self.tick()
            }
        }
    }

    func tick() {
        guard !isSuspended else { return }

        if let idleSince {
            if Date.now.timeIntervalSince(idleSince) >= 5 {
                clearNowPlaying()
            }

            return
        }

        guard hasStarted, !isPaused else { return }

        var newSeconds = seconds + .seconds(1)
        if let runtime {
            newSeconds = min(newSeconds, runtime)
        }

        seconds = newSeconds
    }
}
