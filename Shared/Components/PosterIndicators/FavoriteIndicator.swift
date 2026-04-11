//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FavoriteIndicator: View {

    let size: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.clear

            Image(systemName: "heart.circle.fill")
                .resizable()
                .frame(width: size, height: size)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .pink)
                .padding(3)
        }
    }
}
