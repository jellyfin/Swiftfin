//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import Combine
import Defaults
import Factory
import Foundation
import JellyfinAPI
import MediaPlayer
import UIKit
import VLCUI

// TODO: proper error catching
// TODO: better solution for previous/next/queuing
// TODO: should view models handle progress reports instead, with a protocol
//       for other types of media handling
// TODO: set playback rate
//       - what if proxy couldn't set rate?

protocol MediaPlayerListener {

    var manager: MediaPlayerManager? { get set }
}

typealias MediaPlayerItemProvider = () async throws -> MediaPlayerItem

class MediaPlayerManager: ViewModel, Eventful, Stateful {
    
    enum PlaybackRequestStatus {
        case playing
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

//        case seek(seconds: TimeInterval)
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
    var rate: Float = 1.0 {
        didSet {
            proxy?.setRate(rate)
        }
    }

    @Published
    private(set) var queue: [BaseItemDto] = []
    @Published
    var playbackRequestStatus: PlaybackRequestStatus = .playing
    @Published
    final var state: State = .playback

    @Published
    private(set) var seconds: TimeInterval = 0

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

    var proxy: MediaPlayerProxy?
    private var itemBuildTask: AnyCancellable?

    // MARK: init

    init(item: BaseItemDto, playbackItemProvider: @escaping MediaPlayerItemProvider) {
        self.item = item
        super.init()

        supplements = [MediaInfoSupplement(item: item)]

        // TODO: don't build on init?
        buildMediaItem(from: playbackItemProvider) { @MainActor newItem in
            self.state = .playback
            self.playbackItem = newItem
            self.eventSubject.send(.playNew(playbackItem: newItem))
        }
    }

    init(playbackItem: MediaPlayerItem) {
        item = playbackItem.baseItem
        super.init()

        supplements = [MediaInfoSupplement(item: playbackItem.baseItem)]

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
        if playbackRequestStatus != self.playbackRequestStatus {
            self.playbackRequestStatus = playbackRequestStatus
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
