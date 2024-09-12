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

protocol VideoPlayerDrawerProvider {

    associatedtype Body: View

    var title: String { get }

    func makeBody() -> Self.Body
}

struct ChapterDrawerButton: VideoPlayerDrawerProvider {

    let title: String = "Chapters"

    func makeBody() -> some View {
        Color.red
    }
}

struct ItemInfoDrawerProvider: VideoPlayerDrawerProvider {

    let title: String = "Info"

    func makeBody() -> some View {
        Color.red
    }
}
