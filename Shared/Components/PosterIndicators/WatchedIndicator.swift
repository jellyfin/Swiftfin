//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: make icon-based indicators relative container size based
// TODO: remove favorited

enum PosterOverlayIndicator: String, CaseIterable, Storable {

    case favorited
    case played
    case progress
    case unplayed

    static let favoritedBody = FavoriteIndicator()
    static let playedBody = PlayedIndicator()
    static func progressBody(for progress: Double) -> some View {
//        ProgressIndicator(progress: progress)
        EmptyView()
    }

    static let unplayedBody = UnplayedIndicator()
}

struct PlayedIndicator: View {

    @Default(.accentColor)
    private var accentColor

    var body: some View {
        ContainerRelativeView(
            alignment: .bottomTrailing,
            ratio: 0.2
        ) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .symbolRenderingMode(.palette)
                .aspectRatio(1, contentMode: .fit)
                .foregroundStyle(.white, accentColor)
        }
        .padding(5)
    }
}
