//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import OrderedCollections
import SwiftUI

//class MediaPlayerQueue: MediaPlayerListener, MediaPlayerSupplement {
//
//    let title: String = "Queue"
//
//    weak var manager: MediaPlayerManager?
//
//    private(set) var items: OrderedSet<BaseItemDto> = []
//
//    init(manager: MediaPlayerManager? = nil) {
//        self.manager = manager
//    }
//
//    func videoPlayerBody() -> some View {
//        Color.red
//            .opacity(0.5)
//    }
//}

protocol MediaPlayerQueue: MediaPlayerListener, MediaPlayerSupplement {
    
    var hasNextItem: Bool { get }
    var hasPreviousItem: Bool { get }
    
    var items: OrderedSet<BaseItemDto> { get set }
}

extension MediaPlayerQueue {
    
    var hasNextItem: Bool {
        guard let currentItem = manager?.item else { return false }
        return items.last != currentItem
    }
    
    var hasPreviousItem: Bool {
        guard let currentItem = manager?.item else { return false }
        return items.first != currentItem
    }
}

class EpisodeMediaPlayerQueue: ObservableObject, MediaPlayerQueue {
    
    weak var manager: MediaPlayerManager?
    
    var items: OrderedSet<BaseItemDto> = []
    let title: String = "Up Next"
    
    var id: String {
        "EpisodeMediaPlayerQueue"
    }
    
    func videoPlayerBody() -> some View {
        PosterHStack(type: .portrait, items: items)
    }
}
