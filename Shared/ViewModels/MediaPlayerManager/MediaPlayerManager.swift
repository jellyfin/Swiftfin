//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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

typealias MediaPlayerItemProvider = () async throws -> MediaPlayerItem

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

        case playNew(item: BaseItemDto, mediaSource: MediaSourceInfo)
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
    private(set) var playbackItem: MediaPlayerItem? = nil {
        didSet {
            if let playbackItem {
                seconds = playbackItem.baseItem.startTimeSeconds
                supplements += playbackItem.supplements
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
    private(set) var queue: (any MediaPlayerQueue)?

    /// Listeners of the media player.
    var listeners: [any MediaPlayerListener] = []

    /// Supplements of the media player.
    ///
    /// Supplements are ordered as:
    /// - MediaPlayerManager provided supplements
    /// - PlaybackItem provided supplements
    @Published
    private(set) var supplements: [any MediaPlayerSupplement] = []

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private let eventSubject: PassthroughSubject<Event, Never> = .init()
    private var itemBuildTask: AnyCancellable?

    // MARK: init

    init(item: BaseItemDto, queue: (any MediaPlayerQueue)? = nil, playbackItemProvider: @escaping MediaPlayerItemProvider) {
        self.item = item
        self.queue = queue
        super.init()
        
        self.queue?.manager = self

        supplements = [MediaInfoSupplement(item: item)]
            .appending(ifLet: queue)

        // TODO: don't build on init?
        buildMediaItem(from: playbackItemProvider) { @MainActor newItem in
            self.state = .playback
            self.playbackItem = newItem
            self.eventSubject.send(.playNew(playbackItem: newItem))
        }
    }

    init(playbackItem: MediaPlayerItem, queue: (any MediaPlayerQueue)? = nil) {
        self.item = playbackItem.baseItem
        self.queue = queue
        super.init()
        
        self.queue?.manager = self

        supplements = [MediaInfoSupplement(item: playbackItem.baseItem)]
            .appending(ifLet: queue)

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
//        case let .playNew(item: item, mediaSource: mediaSource):
        case .playNew:

            return .playback
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

        itemBuildTask = Task { [weak self] in
            do {

                await MainActor.run { [weak self] in
                    self?.state = .loadingItem
                }

                let playbackItem = try await provider()

//                try await Task.sleep(nanoseconds: 3_000_000_000)

                await onComplete(playbackItem)
            } catch {
                guard let self, !Task.isCancelled else { return }

                await MainActor.run {
                    self.send(.error(.init(error.localizedDescription)))
                }
            }
        }
        .asAnyCancellable()
    }
}
