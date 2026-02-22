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
        case setBitrate(bitrate: PlaybackBitrate)
        case setPlaybackRequestStatus(status: PlaybackRequestStatus)
        case setRate(rate: Float)
        case setTrack(type: MediaStreamType, from: Int?, to: Int? = nil)
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
            if let playbackItem {
                self.item = playbackItem.baseItem
                seconds = playbackItem.baseItem.startSeconds ?? .zero
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
    var rate: Float = 1.0
    @Published
    var queue: AnyMediaPlayerQueue? = nil

    @Published
    var supplements: [any MediaPlayerSupplement] = []

    // TODO: replace with graph dependency package
    private func setSupplements() {
        var newSupplements: [any MediaPlayerSupplement] = []

        newSupplements.append(MediaInfoSupplement(item: item))

        if let chapters = item.fullChapterInfo, chapters.isNotEmpty {
            newSupplements.append(
                MediaChaptersSupplement(
                    chapters: chapters
                )
            )
        }

        if let queue {
            newSupplements.append(queue)
        }

        self.supplements = newSupplements
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
            if var proxy {
                proxy.manager = self
            }
        }
    }

    private var itemBuildTask: AnyCancellable?
    private var itemUpdateTask: AnyCancellable?

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

        self.queue?.manager = self
        self.playbackItem = playbackItem
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

        if let nextItem = queue?.nextItem, Defaults[.VideoPlayer.autoPlayEnabled] {
            await self.playNewItem(provider: nextItem)
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

    @Function(\Action.Cases.setBitrate)
    private func _setBitrate(_ requestedBitrate: PlaybackBitrate) async throws {
        guard let currentItem = playbackItem else { return }

        try await updateMediaPlayerItem(
            currentItem: currentItem,
            requestedBitrate: requestedBitrate
        )
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

    @Function(\Action.Cases.setTrack)
    private func _setTrack(_ type: MediaStreamType, _ oldIndex: Int?, _ newIndex: Int?) async throws {
        guard let currentItem = playbackItem else {
            logger.warning("MediaPlayerManager.SetTrack call with an invalid playbackItem")
            return
        }

        switch type {
        case .audio:
            guard currentItem.audioStreams.first(where: { $0.index == newIndex }) != nil else {
                logger.warning("MediaPlayerManager.SetTrack call with an invalid audio track index")
                return
            }

            try await updateMediaPlayerItem(
                currentItem: currentItem,
                audioStreamIndex: newIndex
            )
        case .subtitle:
            guard currentItem.subtitleStreams.first(where: { $0.index == newIndex }) != nil else {
                logger.warning("MediaPlayerManager.SetTrack call with an invalid subtitle track index")
                return
            }

            if currentItem.isRebuildRequired(from: oldIndex, to: newIndex) {
                try await updateMediaPlayerItem(
                    currentItem: currentItem,
                    subtitleStreamIndex: newIndex
                )
            } else {
                currentItem.switchSubtitleTrack(index: newIndex)
            }
        default:
            logger.warning("MediaPlayerManager.SetTrack called with unsupported type: \(String(describing: type))")
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

        // TODO: remove playback item?
        //       - check that observers would respond correctly to stopping
        itemBuildTask?.cancel()
        itemUpdateTask?.cancel()
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

    /// Rebuilds the playback item with new stream indexes / bitrate.
    /// Stops the current proxy, requests new playback info from the server, and starts playback with the new configuration.
    private func updateMediaPlayerItem(
        currentItem: MediaPlayerItem,
        audioStreamIndex: Int? = nil,
        subtitleStreamIndex: Int? = nil,
        requestedBitrate: PlaybackBitrate? = nil
    ) async throws {

        itemUpdateTask?.cancel()

        /// Capture the current playback position before stopping
        let currentSeconds = self.seconds

        logger.info(
            "Rebuilding Media Player Item",
            metadata: [
                "audioIndex": .stringConvertible(audioStreamIndex ?? -1),
                "subtitleIndex": .stringConvertible(subtitleStreamIndex ?? -1),
                "currentSeconds": .stringConvertible(currentSeconds),
            ]
        )

        proxy?.stop()

        let newItem = try await MediaPlayerItem.build(
            for: currentItem.baseItem,
            mediaSource: currentItem.mediaSource,
            audioStreamIndex: audioStreamIndex ?? currentItem.selectedAudioStreamIndex,
            subtitleStreamIndex: subtitleStreamIndex ?? currentItem.selectedSubtitleStreamIndex,
            requestedBitrate: requestedBitrate ?? currentItem.requestedBitrate,
            modifyItem: { item in
                if item.userData == nil {
                    item.userData = UserItemDataDto()
                }
                item.userData?.playbackPositionTicks = currentSeconds.ticks
            }
        )

        logger.info(
            "Built new playback item",
            metadata: [
                "playSessionID": .stringConvertible(newItem.playSessionID),
                "isTranscoding": .stringConvertible(newItem.mediaSource.transcodingURL != nil),
                "url": .stringConvertible(newItem.url.absoluteString),
            ]
        )
        self.playbackItem = newItem
        self.seconds = currentSeconds
    }
}
