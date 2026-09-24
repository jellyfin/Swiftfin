//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

enum MediaPlayerSupplementPresentationStyle: Equatable {
    case regular
    case expanded
}

@MainActor
protocol MediaPlayerSupplement: Displayable, Identifiable {

    associatedtype VideoPlayerBody: PlatformView

    var id: String { get }
    var presentationStyle: MediaPlayerSupplementPresentationStyle { get }
    var preferredFocusID: String { get }

    var overlayActions: [VideoPlayerOverlayAction] { get }

    @MainActor
    @ViewBuilder
    var videoPlayerBody: Self.VideoPlayerBody { get }
}

extension MediaPlayerSupplement {

    var overlayActions: [VideoPlayerOverlayAction] {
        []
    }

    var presentationStyle: MediaPlayerSupplementPresentationStyle {
        .regular
    }

    var preferredFocusID: String {
        VideoPlayer.ViewState.Focus.supplementContent(id)
    }
}
