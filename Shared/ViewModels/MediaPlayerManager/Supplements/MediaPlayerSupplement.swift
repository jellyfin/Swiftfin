//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

// TODO: fullscreen supplement styles
// TODO: break out

struct AnyMediaPlayerSupplement: Equatable, Identifiable {

    let supplement: any MediaPlayerSupplement

    var id: String {
        supplement.id
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.supplement.id == rhs.supplement.id
    }
}

protocol MediaPlayerSupplement: Identifiable<String> {

    associatedtype VideoPlayerBody: View

    var title: String { get }

    func videoPlayerBody() -> Self.VideoPlayerBody
}

extension MediaPlayerSupplement {

    var asAny: AnyMediaPlayerSupplement {
        AnyMediaPlayerSupplement(supplement: self)
    }
}

extension MediaPlayerSupplement where VideoPlayerBody == EmptyView {

    func makeBody() -> EmptyView {
        EmptyView()
    }
}
