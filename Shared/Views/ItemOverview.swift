//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemOverviewView: View {

    @Router
    private var router

    let item: BaseItemDto

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {

                #if os(tvOS)
                Text(item.displayTitle)
                    .font(.title)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 200)
                #endif

                if let firstTagline = item.taglines?.first {
                    Text(firstTagline)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                }

                if let itemOverview = item.overview {
                    Text(itemOverview)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .edgePadding()
        }
        .scrollIndicators(.hidden)
        .navigationTitle(item.displayTitle)
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
    }
}
