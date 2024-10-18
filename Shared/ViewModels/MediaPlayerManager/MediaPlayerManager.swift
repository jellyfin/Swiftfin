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

class MediaPlayerManager: ViewModel, Eventful, Stateful {
    
    // MARK: Event

    enum Event {
        case playbackStopped
        case playNew(playbackItem: MediaPlayerItem)
    }
    
    // MARK: Action

    // TODO: have play new MediaPlayerItem
    indirect enum Action: Equatable {

        case error(JellyfinAPIError)

        case pause
        case play
        case buffer
        case ended
        case stop

        case playNew(item: BaseItemDto, mediaSource: MediaSourceInfo)
//        case playNew(item: MediaPlayerItem)

        case seek(seconds: TimeInterval)
    }
    
    // MARK: State

    enum State: Hashable {
        case initial
        case loadingItem
        case error(JellyfinAPIError)

        case playing
        case paused
        case buffering
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
    var playbackRate: PlaybackRate = .one {
        didSet {
            proxy?.setRate(Float(playbackRate.rate))
        }
    }
    @Published
    private(set) var queue: [BaseItemDto] = []
    @Published
    final var state: State = .initial
    
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

    init(item: BaseItemDto, playbackItemProvider: @escaping () async throws -> MediaPlayerItem) {
        self.item = item
        super.init()
        
        supplements = [MediaInfoSupplement(item: item)]

        // TODO: don't build on init?
        buildMediaItem(from: playbackItemProvider)
    }

    init(playbackItem: MediaPlayerItem) {
        item = playbackItem.baseItem
        super.init()
        
        supplements = [MediaInfoSupplement(item: playbackItem.baseItem)]

        state = .buffering
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
        case .pause:

            return .paused
        case .play:

            return .playing
        case .buffer:
            return .buffering
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

            return .buffering
        case let .seek(newSeconds):
            seconds = newSeconds
            return state
        }
    }
    
    // MARK: buildMediaItem

    private func buildMediaItem(from provider: @escaping () async throws -> MediaPlayerItem) {
        itemBuildTask?.cancel()

        itemBuildTask = Task { [weak self] in
            do {

                await MainActor.run { [weak self] in
                    self?.state = .loadingItem
                }

                let playbackItem = try await provider()
                
//                try await Task.sleep(nanoseconds: 3_000_000_000)

                guard let self else { return }

                await MainActor.run {
                    self.state = .buffering
                    self.playbackItem = playbackItem
                    self.eventSubject.send(.playNew(playbackItem: playbackItem))
                }
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
