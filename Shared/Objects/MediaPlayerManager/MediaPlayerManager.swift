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
// TODO: video player stop on presentation dismissal

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
                seconds = playbackItem.baseItem.startSeconds ?? .zero
                playbackItem.manager = self

                Task { _ = await playbackItem.previewImageProvider?.image(for: seconds) }
            }
        }
    }

    @Published
    private(set) var item: BaseItemDto
    @Published
    private(set) var playbackRequestStatus: PlaybackRequestStatus = .playing
    @Published
    private(set) var rate: Float = 1.0
    @Published
    final var state: State = .loadingItem

    @Published
    var queue: (any MediaPlayerQueue)?

    @Published
    private var _supplements: [any MediaPlayerSupplement] = []

    // TODO: ensure supplement container updates
    // TODO: need supplements at manager level?
    //       - supplements of the proxy vs media player item?
//    @Published
    private(set) var supplements: [any MediaPlayerSupplement] {
        get { _supplements.appending(queue!, if: queue != nil) }
        set { _supplements = newValue }
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

    // MARK: init

    init(
        item: BaseItemDto,
        queue: (any MediaPlayerQueue)? = nil,
        mediaPlayerItemProvider: @escaping MediaPlayerItemProviderFunction
    ) {
        self.item = item
        self.queue = queue
        super.init()

        self.queue?.manager = self

        // TODO: don't build on init?
        buildMediaItem(from: .init(item: item, function: mediaPlayerItemProvider)) { @MainActor newItem in
            self.playbackItem = newItem
            self.supplements = newItem.supplements
        }
    }

    init(
        playbackItem: MediaPlayerItem,
        queue: (any MediaPlayerQueue)? = nil
    ) {
        self.item = playbackItem.baseItem
        self.queue = queue
        super.init()

        self.queue?.manager = self

        state = .playback
        self.playbackItem = playbackItem
        self.supplements = playbackItem.supplements
    }

    // MARK: respond

    @MainActor
    func respond(to action: Action) -> State {

        guard state != .stopped else { return .stopped }

        switch action {
        case let .error(error):
            proxy?.stop()
            return .error(error)
        case .ended:
            // TODO: verify live items
            // TODO: autoplay

            // Ended should represent natural ending of playback, which
            // is verifiable by given seconds being near item runtime.
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
            proxy?.stop()
            return .stopped
        case let .playNewItem(provider: provider):
            self.item = provider.item
            buildMediaItem(from: provider) { @MainActor newItem in
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
