//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Factory
import Foundation
import JellyfinAPI
import VLCUI

// TODO: proper error catching

typealias MediaPlayerManagerPublisher = LegacyEventPublisher<MediaPlayerManager?>

extension Scope {
    static let session = Cached()
}

extension Container {

    var mediaPlayerManagerPublisher: Factory<MediaPlayerManagerPublisher> {
        self { MediaPlayerManagerPublisher() }
            .singleton
    }

    var mediaPlayerManager: Factory<MediaPlayerManager> {
        self { @MainActor in
            .init(
                playbackItem: .init(
                    baseItem: .init(),
                    mediaSource: .init(),
                    playSessionID: "",
                    url: URL(string: "/")!
                )
            )
        }
        .scope(.session)
    }
}

import StatefulMacros

@MainActor
@Stateful
final class MediaPlayerManager: ViewModel {

    @CasePathable
    enum Action {
        case ended
        case error
        case playNewItem(provider: MediaPlayerItemProvider)
        case setPlaybackRequestStatus(status: PlaybackRequestStatus)
        case setRate(rate: Float)
        case start
        case stop
        case togglePlayPause

        var transition: Transition {
            switch self {
            case .error:
                .to(.error)
                    .invalid(.stopped)
            case .playNewItem, .start:
                .to(.loadingItem, then: .playback)
                    .invalid(.stopped)
            case .stop:
                .to(.stopped)
            default:
                .none
                    .invalid(.stopped)
            }
        }
    }

    enum State {
        case error
        case initial
        case loadingItem
        case playback
        case stopped
    }

    /// A status indicating the player's request for media playback.
    enum PlaybackRequestStatus {

        /// The player requests media playback
        case playing

        /// The player is paused
        case paused
    }

    @Published
    var playbackItem: MediaPlayerItem? = nil {
        didSet {
            fallbackPlayerType = nil
            if let playbackItem {
                self.item = playbackItem.baseItem
                seconds = playbackItem.baseItem.startSeconds ?? .zero
                playbackRequestStatus = .playing
                playbackItem.manager = self
                setSupplements()

                logger.info(
                    "Playing new item",
                    metadata: [
                        "itemID": .stringConvertible(playbackItem.baseItem.id ?? "Unknown"),
                        "itemTitle": .stringConvertible(playbackItem.baseItem.displayTitle),
                        "url": .stringConvertible(playbackItem.url.absoluteString),
                    ]
                )

                Task { _ = await playbackItem.previewImageProvider?.image(for: seconds) }
            }
        }
    }

    @Published
    private(set) var item: BaseItemDto
    @Published
    private(set) var playbackRequestStatus: PlaybackRequestStatus = .playing
    @Published
    var rate: Float = Defaults[.VideoPlayer.Playback.playbackRate] {
        didSet {
            Defaults[.VideoPlayer.Playback.playbackRate] = rate
        }
    }

    @Published
    var queue: AnyMediaPlayerQueue? = nil

    @Published
    var supplements: [any MediaPlayerSupplement] = []

    private(set) var remote: RemotePlaybackManager!

    // TODO: replace with graph dependency package
    private func setSupplements() {
        self.supplements = Defaults[.VideoPlayer.supplements].compactMap { kind -> (any MediaPlayerSupplement)? in
            switch kind {
            case .info:
                return MediaInfoSupplement(item: item)
            case .chapters:
                guard let chapters = item.fullChapterInfo, chapters.isNotEmpty else { return nil }
                return MediaChaptersSupplement(chapters: chapters)
            case .queue:
                return queue
            case .people:
                guard let people = item.people?.filter({ $0.type?.isSupported == true }), people.isNotEmpty else { return nil }
                return MediaPeopleSupplement(people: people)
            case .playbackInformation:
                guard let itemID = item.id else { return nil }
                return PlaybackInformationSupplement(itemID: itemID)
            }
        }
    }

    /// The current seconds media playback is set to.
    let secondsBox: PublishedBox<Duration> = .init(initialValue: .zero)

    var seconds: Duration {
        get { secondsBox.value }
        set { secondsBox.value = newValue }
    }

    /// Holds a weak reference to the current media player proxy.
    weak var proxy: (any MediaPlayerProxy)? {
        didSet {
            objectWillChange.send()
            if var proxy {
                proxy.manager = self
            }
        }
    }

    /// `nil` when playback is fully remote (a session, no local engine).
    var videoPlayerType: VideoPlayerType? {
        if proxy is any RemotePlaybackSession {
            return nil
        }
        return (proxy as? any VideoMediaPlayerProxy)?.videoPlayerType
            ?? Defaults[.VideoPlayer.mediaPlaybackStrategy].forcedPlayer
    }

    private var isSwitchingPlayer = false
    private var fallbackPlayerType: VideoPlayerType?

    private var itemBuildTask: AnyCancellable?

    private var initialMediaPlayerItemProvider: MediaPlayerItemProvider?

    // MARK: init

//    static let empty: MediaPlayerManager = .init()

//    override private init() {
//        self.item = .init()
//        self.state = .stopped
//        super.init()
//    }

    init(
        item: BaseItemDto,
        queue: (any MediaPlayerQueue)? = nil,
        mediaPlayerItemProvider: @escaping MediaPlayerItemProviderFunction
    ) {
        self.item = item
        self.queue = queue.map { AnyMediaPlayerQueue($0) }
        self.state = .loadingItem
        self.initialMediaPlayerItemProvider = .init(
            item: item,
            function: mediaPlayerItemProvider
        )
        super.init()

        // Seed from the item's resume point so a cast/AirPlay started before the
        // video loads transfers from the right position, not zero.
        seconds = item.startSeconds ?? .zero

        setUpRemote()
        self.queue?.manager = self
    }

    init(
        playbackItem: MediaPlayerItem,
        queue: (any MediaPlayerQueue)? = nil
    ) {
        self.item = playbackItem.baseItem
        self.queue = queue.map { AnyMediaPlayerQueue($0) }
        self.state = .playback
        super.init()

        setUpRemote()
        self.queue?.manager = self
        self.playbackItem = playbackItem
    }

    private func setUpRemote() {
        let remote = RemotePlaybackManager(manager: self)
        remote.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
        self.remote = remote
    }

    @Function(\Action.Cases.ended)
    private func _ended() async throws {
        // TODO: change to observe given seconds against runtime
        //       instead of sent action?

        // Ended should represent natural ending of playback, which
        // is verifiable by given seconds being near item runtime.
        // VLC proxy will send ended early.
        guard let runtime = item.runtime else {
            await self.stop()
            return
        }
        let isNearEnd = (runtime - seconds) <= .seconds(1)

        guard isNearEnd else {
            // If not near end, ignore.
            return
        }

        if let nextItem = queue?.nextItem, userSession.user.data.configuration?.enableNextEpisodeAutoPlay == true {
            await self.playNewItem(provider: nextItem)
        } else {
            await self.stop()
        }
    }

    @Function(\Action.Cases.error)
    private func onError(_ error: Error) async throws {
        if let playbackItem {
            logger.error(
                "Error while playing item",
                metadata: [
                    "error": .stringConvertible(error.localizedDescription),
                    "itemID": .stringConvertible(playbackItem.baseItem.id ?? "Unknown"),
                    "itemTitle": .stringConvertible(playbackItem.baseItem.displayTitle),
                    "url": .stringConvertible(playbackItem.url.absoluteString),
                ]
            )
        } else {
            logger.error(
                "Error with no playback item",
                metadata: [
                    "error": .stringConvertible(error.localizedDescription),
                    "itemID": .stringConvertible(item.id ?? "Unknown"),
                    "itemTitle": .stringConvertible(item.displayTitle),
                ]
            )
        }

        if let fallback = fallbackPlayerType {
            remote.setAirPlayActive(false)
            await switchPlayer(to: fallback, isFallback: true)
            return
        }

        proxy?.stop()
        Container.shared.mediaPlayerManager.reset()
    }

    @Function(\Action.Cases.playNewItem)
    private func _playNewItem(_ provider: MediaPlayerItemProvider) async throws {
        item = provider.item
        setSupplements()
        proxy?.stop()
        playbackItem = try await provider()
    }

    @Function(\Action.Cases.setPlaybackRequestStatus)
    private func set(_ status: PlaybackRequestStatus) {
        if self.playbackRequestStatus != status {
            self.playbackRequestStatus = status

            switch status {
            case .paused:
                proxy?.pause()
            case .playing:
                proxy?.play()
            }
        }
    }

    @Function(\Action.Cases.setRate)
    private func set(_ rate: Float) {
        if self.rate != rate {
            self.rate = rate
        }
    }

    @Function(\Action.Cases.start)
    private func _start() async throws {
        guard let initialMediaPlayerItemProvider else {
            await self.stop()
            return
        }
        self.initialMediaPlayerItemProvider = nil
        playbackItem = try await initialMediaPlayerItemProvider()
    }

    @Function(\Action.Cases.stop)
    private func _stop() async throws {
        await self.cancel()

        itemBuildTask?.cancel()
        remote.stop()
        proxy?.stop()
        Container.shared.mediaPlayerManager.reset()
    }

    @Function(\Action.Cases.togglePlayPause)
    private func _togglePlayPause() {
        switch playbackRequestStatus {
        case .playing:
            setPlaybackRequestStatus(status: .paused)
        case .paused:
            setPlaybackRequestStatus(status: .playing)
        }
    }
}

// MARK: - Player switch

extension MediaPlayerManager {

    func switchPlayer(to type: VideoPlayerType, isFallback: Bool = false) async {
        guard !isSwitchingPlayer,
              let item = playbackItem,
              item.videoPlayerType != type
        else { return }

        isSwitchingPlayer = true
        defer { isSwitchingPlayer = false }

        let previousType = item.videoPlayerType
        let positionTicks = seconds.ticks

        do {
            let switched = try await MediaPlayerItem.build(
                for: item.baseItem,
                mediaSource: item.mediaSource,
                strategy: .player(type),
                requestedBitrate: item.requestedBitrate
            ) { base in
                // `modifyItem` runs after `getFullItem`'s re-fetch, which would
                // otherwise restore the server's stale position.
                if base.userData == nil { base.userData = .init() }
                base.userData?.playbackPositionTicks = positionTicks
            }

            logger.info(
                "⏱ switchPlayer \(previousType)→\(type): captured=\(seconds.seconds)s builtStart=\(switched.baseItem.startSeconds?.seconds ?? -1)s offset=\(switched.transcodeStartOffset.seconds)s transcoding=\(switched.isTranscoding)"
            )

            playbackItem = switched
            fallbackPlayerType = isFallback ? nil : previousType
        } catch {
            logger.error("Failed to switch player: \(error.localizedDescription)")
        }
    }

    func resumeLocal(on proxy: any MediaPlayerProxy) async {
        guard let item = playbackItem,
              let type = (proxy as? any VideoMediaPlayerProxy)?.videoPlayerType
        else {
            self.proxy = proxy
            return
        }

        let positionTicks = seconds.ticks

        do {
            let resumed = try await MediaPlayerItem.build(
                for: item.baseItem,
                mediaSource: item.mediaSource,
                strategy: .player(type),
                requestedBitrate: item.requestedBitrate
            ) { base in
                if base.userData == nil { base.userData = .init() }
                base.userData?.playbackPositionTicks = positionTicks
            }

            logger.info(
                "⏱ resumeLocal \(type): captured=\(seconds.seconds)s builtStart=\(resumed.baseItem.startSeconds?.seconds ?? -1)s offset=\(resumed.transcodeStartOffset.seconds)s transcoding=\(resumed.isTranscoding)"
            )

            playbackItem = resumed
        } catch {
            logger.error("Failed to resume local playback: \(error.localizedDescription)")
        }

        self.proxy = proxy
    }
}

// MARK: - Picture in Picture

extension MediaPlayerManager {

    func startPictureInPicture() {
        guard let pipable = proxy as? any PictureInPictureable else { return }

        if pipable.supportsPiP {
            Task { await startPiPWhenReady(attemptsLeft: 20) }
            return
        }

        guard let target = pipable.pipPlayerType else { return }

        Task {
            await switchPlayer(to: target)
            await startPiPWhenReady(attemptsLeft: 20)
        }
    }

    func stopPictureInPicture() {
        (proxy as? MediaPlayerPictureInPictureCapable)?.stopPiP()
    }

    // Retries because the proxy swap is async and AVKit ignores an early start.
    private func startPiPWhenReady(attemptsLeft: Int) async {
        guard attemptsLeft > 0,
              let capable = proxy as? MediaPlayerPictureInPictureCapable
        else { return }

        if capable.isPiPActive.value { return }

        if capable.isPiPAvailable.value {
            capable.startPiP()
        }

        try? await Task.sleep(for: .milliseconds(300))
        await startPiPWhenReady(attemptsLeft: attemptsLeft - 1)
    }
}
