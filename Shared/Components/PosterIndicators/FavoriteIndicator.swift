//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FavoriteIndicator: View {

    var body: some View {
        ContainerRelativeView(
            alignment: .bottomLeading,
            ratio: 0.2
        ) {
            Image(systemName: "heart.circle.fill")
                .resizable()
                .symbolRenderingMode(.palette)
                .aspectRatio(1, contentMode: .fit)
                .foregroundStyle(.white, .pink)
        }
        .padding(5)
    }
}
