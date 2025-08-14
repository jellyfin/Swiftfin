//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import VLCUI

// TODO: proper error catching
// TODO: set playback rate
//       - what if proxy couldn't set rate?
// TODO: buffering state
// TODO: make a container service, injected into players
// TODO: change playback item + provider to just a provider

typealias MediaPlayerItemProviderFunction = (BaseItemDto) async throws -> MediaPlayerItem

struct MediaPlayerItemProvider: Equatable {

    let item: BaseItemDto
    let function: MediaPlayerItemProviderFunction

    static func == (lhs: MediaPlayerItemProvider, rhs: MediaPlayerItemProvider) -> Bool {
        false
    }

    func callAsFunction() async throws -> MediaPlayerItem {
        try await function(item)
    }
}

class MediaPlayerManager: ViewModel, Stateful {

    /// A status indicating the player's request for media playback.
    enum PlaybackRequestStatus {

        /// The player requests media playback
        case playing

        /// The player is paused
        case paused
    }

    // MARK: Event

    // TODO: remove and just have downstream listen to playbackItem and state?
//    enum Event {
//        case playbackStopped
//        case itemChanged(playbackItem: MediaPlayerItem)
//    }

    // MARK: Action

    // TODO: have play new MediaPlayerItem
    indirect enum Action: Equatable {

        case error(JellyfinAPIError)
        case ended
        case stop

        case playNewBaseItem(provider: MediaPlayerItemProvider)
        // TODO: - Equatable
//        case playNewMdiaItem(item: MediaPlayerItem)
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

                for var o in observers {
                    o.manager = self
                }
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
    final var state: State = .playback

    /// The current seconds media playback is set to.
    let secondsBox: PublishedBox<Duration> = .init(initialValue: .zero)

    var seconds: Duration {
        get { secondsBox.value }
        set { secondsBox.value = newValue }
    }

    weak var proxy: (any MediaPlayerProxy)? {
        didSet {
            if var proxy {
                proxy.manager = self
            }
        }
    }

    var queue: (any MediaPlayerQueue)?

    /// Observers of the media player.
    var observers: [any MediaPlayerObserver] = []

    /// Supplements of the media player.
    @Published
    private(set) var supplements: [any MediaPlayerSupplement] = []

//    var events: AnyPublisher<Event, Never> {
//        eventSubject
//            .receive(on: RunLoop.main)
//            .eraseToAnyPublisher()
//    }

//    private let eventSubject: PassthroughSubject<Event, Never> = .init()
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
        buildMediaItem(from: mediaPlayerItemProvider) { @MainActor newItem in
            self.state = .playback
            self.playbackItem = newItem
//            self.eventSubject.send(.itemChanged(playbackItem: newItem))
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
//        eventSubject.send(.itemChanged(playbackItem: playbackItem))

        self.supplements = playbackItem.supplements
    }

    // MARK: respond

    @MainActor
    func respond(to action: Action) -> State {

        guard state != .stopped else { return .stopped }

        switch action {
        case let .error(error):
            return .error(error)
        case .ended:
            // TODO: go next in queue or stop
            return .loadingItem
        case .stop:
//            Task { @MainActor in
//                eventSubject.send(.playbackStopped)
//            }
            return .stopped
        case let .playNewBaseItem(provider: provider):
            buildMediaItem(from: provider.function) { @MainActor newItem in
                self.state = .playback
                self.playbackItem = newItem
//                self.eventSubject.send(.itemChanged(playbackItem: newItem))
            }

            return .loadingItem
        }
    }

    @MainActor
    func set(playbackRequestStatus: PlaybackRequestStatus) {
        if self.playbackRequestStatus != playbackRequestStatus {
            self.playbackRequestStatus = playbackRequestStatus
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
        from provider: @escaping MediaPlayerItemProviderFunction,
        onComplete: @escaping (MediaPlayerItem) async -> Void
    ) {
        itemBuildTask?.cancel()

        itemBuildTask = Task {
            do {

                await MainActor.run {
                    self.state = .loadingItem
                }

                let playbackItem = try await provider(self.item)

                await onComplete(playbackItem)
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
