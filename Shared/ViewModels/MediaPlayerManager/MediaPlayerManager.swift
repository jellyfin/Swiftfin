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

protocol MediaPlayerListener {

    var manager: MediaPlayerManager? { get set }
}

typealias MediaPlayerItemProvider = (BaseItemDto) async throws -> MediaPlayerItem

class MediaPlayerManager: ViewModel, Eventful, Stateful {

    /// A status indicating the player's
    /// request for media playback.
    enum PlaybackRequestStatus {

        /// The player requests more info to be playing
        case playing

        /// The player is paused
        case paused
    }

    // MARK: Event

    enum Event {
        case playbackStopped
        case playNew(playbackItem: MediaPlayerItem)
    }

    // MARK: Action

    // TODO: have play new MediaPlayerItem
    indirect enum Action: Equatable {

        case error(JellyfinAPIError)
        case ended
        case stop

        case playNew(item: BaseItemDto)
//        case playNew(item: MediaPlayerItem)
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
                seconds = playbackItem.baseItem.startTimeSeconds
                playbackItem.manager = self
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
    private(set) var seconds: TimeInterval = 0
    @Published
    final var state: State = .playback

    var proxy: MediaPlayerProxy?
    var queue: (any MediaPlayerQueue)?

    /// Listeners of the media player.
    var listeners: [any MediaPlayerListener] = []

    /// Supplements of the media player.
    @Published
    private(set) var supplements: [any MediaPlayerSupplement] = []

    /// The playback item provider that should be used
    /// during the lifetime of this manager
    private let playbackItemProvider: MediaPlayerItemProvider?

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private let eventSubject: PassthroughSubject<Event, Never> = .init()
    private var itemBuildTask: AnyCancellable?

    // MARK: init

    init(
        item: BaseItemDto,
        queue: (any MediaPlayerQueue)? = nil,
        playbackItemProvider: @escaping MediaPlayerItemProvider
    ) {
        self.item = item
        self.queue = queue
        self.playbackItemProvider = playbackItemProvider
        super.init()

        self.queue?.manager = self

        // TODO: don't build on init?
        buildMediaItem(from: playbackItemProvider) { @MainActor newItem in
            self.state = .playback
            self.playbackItem = newItem
            self.eventSubject.send(.playNew(playbackItem: newItem))
        }
    }

    init(
        playbackItem: MediaPlayerItem,
        queue: (any MediaPlayerQueue)? = nil,
        playbackItemProvider: MediaPlayerItemProvider? = nil
    ) {
        self.item = playbackItem.baseItem
        self.queue = queue
        self.playbackItemProvider = playbackItemProvider
        super.init()

        self.queue?.manager = self

        state = .playback
        self.playbackItem = playbackItem
        eventSubject.send(.playNew(playbackItem: playbackItem))
    }

    // MARK: respond

    @MainActor
    func respond(to action: Action) -> State {

        guard state != .stopped else { return .stopped }

        switch action {
        case let .error(error):
            return .error(error)
        case .ended:
            // TODO: go next in queue
            return .loadingItem
        case .stop:
            Task { @MainActor in
                eventSubject.send(.playbackStopped)
            }
            return .stopped
        case let .playNew(item: item):
            guard let playbackItemProvider else {
                return .error(.init("Attempted to play new item from base item, but no playback item provider was provided"))
            }

            self.item = item
            buildMediaItem(from: playbackItemProvider) { @MainActor newItem in
                self.state = .playback
                self.playbackItem = newItem
                self.eventSubject.send(.playNew(playbackItem: newItem))
            }

            return .loadingItem
        }
    }

    @MainActor
    func set(seconds: TimeInterval) {
        self.seconds = seconds
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

    private func buildMediaItem(from provider: @escaping MediaPlayerItemProvider, onComplete: @escaping (MediaPlayerItem) async -> Void) {
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
