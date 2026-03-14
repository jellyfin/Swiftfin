//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

// TODO: fullscreen supplement styles

@MainActor
protocol MediaPlayerSupplement: Displayable, Identifiable {

    associatedtype VideoPlayerBody: PlatformView

    var id: String { get }

    @MainActor
    @ViewBuilder
    var videoPlayerBody: Self.VideoPlayerBody { get }
}

struct AnyMediaPlayerSupplement: MediaPlayerSupplement, Equatable {

    let supplement: any MediaPlayerSupplement

    var displayTitle: String {
        supplement.displayTitle
    }

    var id: String {
        supplement.id
    }

    var videoPlayerBody: some PlatformView {
        supplement.videoPlayerBody
            .eraseToAnyView()
    }

    init(_ supplement: any MediaPlayerSupplement) {
        self.supplement = supplement
    }

    static func == (lhs: AnyMediaPlayerSupplement, rhs: AnyMediaPlayerSupplement) -> Bool {
        lhs.id == rhs.id
    }
}
