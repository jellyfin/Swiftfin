//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

// TODO: break out

struct AnyMediaPlayerSupplement: Equatable, Identifiable {

    let supplement: any MediaPlayerSupplement

    init(supplement: any MediaPlayerSupplement) {
        self.supplement = supplement
    }

    var id: String {
        supplement.id
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.supplement.id == rhs.supplement.id
    }
}

protocol MediaPlayerSupplement: Equatable, Identifiable<String> {

    associatedtype VideoPlayerBody: View

    var title: String { get }

    func makeBody() -> Self.VideoPlayerBody
}

extension MediaPlayerSupplement where VideoPlayerBody == EmptyView {

    func makeBody() -> EmptyView {
        EmptyView()
    }
}

extension MediaPlayerSupplement where ID == String {

    var id: String { title }
}

struct ChapterDrawerButton {

//    weak var manager: MediaPlayerManager?
    let title: String = "Chapters"

    func makeBody() -> some View {
        Color.red
    }
}
