//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemOverviewView: View {

    let item: BaseItemDto

    @ViewBuilder
    private var content: some View {
        GeometryReader { proxy in
            VStack(alignment: .center) {

                Text(item.displayTitle)
                    .font(.title)
                    .frame(maxHeight: proxy.size.height * 0.33)

                VStack(alignment: .leading, spacing: 20) {
                    if let tagline = item.taglines?.first {
                        Text(tagline)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.leading)
                    }

                    if let overview = item.overview {
                        Text(overview)
                    }
                }
            }
            .padding(.horizontal, 100)
        }
    }

    var body: some View {
        ZStack {
            BlurView()

            content
        }
        .ignoresSafeArea()
    }
}
