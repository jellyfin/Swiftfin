//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct PosterIndicator: OptionSet, Storable {
    let rawValue: Int

    static let favorited = PosterIndicator(rawValue: 1 << 0)
    static let played = PosterIndicator(rawValue: 1 << 1)
    static let progress = PosterIndicator(rawValue: 1 << 2)
    static let unplayed = PosterIndicator(rawValue: 1 << 3)
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
