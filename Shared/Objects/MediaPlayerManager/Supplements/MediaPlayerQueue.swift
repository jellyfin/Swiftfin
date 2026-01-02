//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine

@MainActor
protocol MediaPlayerQueue: ObservableObject, MediaPlayerObserver, MediaPlayerSupplement {

    var hasNextItem: Bool { get }
    var hasPreviousItem: Bool { get }

    var nextItem: MediaPlayerItemProvider? { get }
    var previousItem: MediaPlayerItemProvider? { get }

    var hasNextItemPublisher: Published<Bool>.Publisher { get set }
    var hasPreviousItemPublisher: Published<Bool>.Publisher { get set }
    var nextItemPublisher: Published<MediaPlayerItemProvider?>.Publisher { get set }
    var previousItemPublisher: Published<MediaPlayerItemProvider?>.Publisher { get set }
}

extension MediaPlayerQueue {

    var hasNextItem: Bool {
        nextItem != nil
    }

    var hasPreviousItem: Bool {
        previousItem != nil
    }
}

class AnyMediaPlayerQueue: MediaPlayerQueue {

    @Published
    var hasNextItem: Bool
    @Published
    var hasPreviousItem: Bool

    @Published
    var nextItem: MediaPlayerItemProvider?
    @Published
    var previousItem: MediaPlayerItemProvider?

    lazy var hasNextItemPublisher: Published<Bool>.Publisher = $hasNextItem
    lazy var hasPreviousItemPublisher: Published<Bool>.Publisher = $hasPreviousItem
    lazy var nextItemPublisher: Published<MediaPlayerItemProvider?>.Publisher = $nextItem
    lazy var previousItemPublisher: Published<MediaPlayerItemProvider?>.Publisher = $previousItem

    private var wrapped: any MediaPlayerQueue

    var displayTitle: String {
        wrapped.displayTitle
    }

    var id: String {
        wrapped.id
    }

    weak var manager: MediaPlayerManager? {
        get { wrapped.manager }
        set { wrapped.manager = newValue }
    }

    private var cancellables: [AnyCancellable] = []

    init(_ wrapped: some MediaPlayerQueue) {
        self.wrapped = wrapped
        self.hasNextItem = wrapped.hasNextItem
        self.hasPreviousItem = wrapped.hasPreviousItem

        wrapped.hasNextItemPublisher
            .assign(to: &$hasNextItem)
        wrapped.hasPreviousItemPublisher
            .assign(to: &$hasPreviousItem)
        wrapped.nextItemPublisher
            .assign(to: &$nextItem)
        wrapped.previousItemPublisher
            .assign(to: &$previousItem)
    }

    var videoPlayerBody: some PlatformView {
        wrapped
            .videoPlayerBody
            .eraseToAnyView()
    }
}
