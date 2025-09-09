//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Factory
import Foundation
import JellyfinAPI
import VLCUI

// TODO: proper error catching
// TODO: set playback rate
//       - what if proxy couldn't set rate?
// TODO: make a container service, injected into players

extension Container {

    var mediaPlayerManager: Factory<MediaPlayerManager?> {
        self {
            nil
        }.cached
    }
}

final class MediaPlayerManager: ViewModel, Stateful {

    /// A status indicating the player's request for media playback.
    enum PlaybackRequestStatus {

        /// The player requests media playback
        case playing

        /// The player is paused
        case paused
    }

    // MARK: Action

    enum Action: Equatable {
        case error(JellyfinAPIError)
        case ended
        case stop
        case playNewItem(provider: MediaPlayerItemProvider)
        case start
    }

    // MARK: State

    enum State: Hashable {
        case error(JellyfinAPIError)
        case loadingItem
        case playback
        case stopped
    }

    @Published
    var playbackItem: MediaPlayerItem? = nil {
        didSet {
            if let playbackItem {
                self.item = playbackItem.baseItem
                seconds = playbackItem.baseItem.startSeconds ?? .zero
                playbackItem.manager = self
                setSupplements()

                Task { _ = await playbackItem.previewImageProvider?.image(for: seconds) }
            }
        }
    }

    @Published
    private(set) var error: Error? = nil
    @Published
    private(set) var item: BaseItemDto
    @Published
    private(set) var playbackRequestStatus: PlaybackRequestStatus = .playing
    @Published
    private(set) var rate: Float = 1.0
    @Published
    final var state: State

    @Published
    var queue: (any MediaPlayerQueue)?

    // TODO: ensure supplement container updates
    // TODO: need supplements at manager level?
    //       - supplements of the proxy vs media player item?
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

    private var initialMediaPlayerItemProvider: MediaPlayerItemProviderFunction?

    // MARK: init

    init(
        item: BaseItemDto,
        queue: (any MediaPlayerQueue)? = nil,
        mediaPlayerItemProvider: @escaping MediaPlayerItemProviderFunction
    ) {
        self.item = item
        self.queue = queue
        self.state = .loadingItem
        self.initialMediaPlayerItemProvider = mediaPlayerItemProvider
        super.init()

        self.queue?.manager = self
    }

    init(
        playbackItem: MediaPlayerItem,
        queue: (any MediaPlayerQueue)? = nil
    ) {
        self.item = playbackItem.baseItem
        self.queue = queue
        self.state = .playback
        super.init()

        self.queue?.manager = self
        self.playbackItem = playbackItem
    }

    // MARK: respond

    @MainActor
    func respond(to action: Action) -> State {

        guard state != .stopped else { return .stopped }

        switch action {
        case let .error(error):
            self.error = error
            proxy?.stop()
            return .error(error)
        case .ended:
            // TODO: verify live items
            // TODO: autoplay
            // TODO: change to observe given seconds against runtime
            //       instead of sent action?

            // Ended should represent natural ending of playback, which
            // is verifiable by given seconds being near item runtime.
            // VLC proxy will send ended early.
            guard let runtime = playbackItem?.baseItem.runtime else {
                return .stopped
            }
            let isNearEnd = (runtime - seconds) <= .seconds(1)

            guard isNearEnd else {
                // If not near end, ignore.
                return state
            }

            if let nextItem = queue?.nextItem, Defaults[.VideoPlayer.autoPlayEnabled] {
                return respond(to: .playNewItem(provider: nextItem))
            }

            return .stopped
        case .stop:
            // TODO: remove playback item?
            //       - check that observers would respond well
            proxy?.stop()
            guard self.state != .loadingItem else { return state }

            return .stopped
        case let .playNewItem(provider: provider):
            self.item = provider.item
            setSupplements()
            proxy?.stop()

            buildMediaItem(from: provider) { @MainActor newItem in
                self.playbackItem = newItem
            }

            return .loadingItem
        case .start:
            guard let initialMediaPlayerItemProvider else { return state }
            self.initialMediaPlayerItemProvider = nil

            buildMediaItem(from: .init(item: item, function: initialMediaPlayerItemProvider)) { @MainActor newItem in
                self.playbackItem = newItem
            }

            return .loadingItem
        }
    }

    @MainActor
    func togglePlayPause() {
        switch playbackRequestStatus {
        case .playing:
            set(playbackRequestStatus: .paused)
        case .paused:
            set(playbackRequestStatus: .playing)
        }
    }

    @MainActor
    func set(playbackRequestStatus: PlaybackRequestStatus) {
        if self.playbackRequestStatus != playbackRequestStatus {
            self.playbackRequestStatus = playbackRequestStatus

            if playbackRequestStatus == .paused {
                proxy?.pause()
            } else {
                proxy?.play()
            }
        }
    }

    @MainActor
    func set(rate: Float) {
        if self.rate != rate {
            self.rate = rate
        }
    }

    // MARK: buildMediaItem

    private func buildMediaItem(
        from provider: MediaPlayerItemProvider,
        onComplete: @escaping (MediaPlayerItem) async -> Void
    ) {
        itemBuildTask?.cancel()

        itemBuildTask = Task {
            do {

                await MainActor.run {
                    self.state = .loadingItem
                }

                let playbackItem = try await provider.function(provider.item)

                await onComplete(playbackItem)

                await MainActor.run {
                    self.state = .playback
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.send(.error(.init(error.localizedDescription)))
                }
            }
        }
        .asAnyCancellable()
    }
}
