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

    @AdaptiveLayout
    private var viewLayout

    @Router
    private var router

    @SharedBaseItem
    var item: BaseItemDto

    @ContentBuilder
    private var content: some View {
        VStack(alignment: viewLayout.value(standard: .leading, large: .center), spacing: 10) {
            if let firstTagline = item.taglines?.first {
                Text(firstTagline)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
            }

            if let itemOverview = item.richOverview {
                Text(itemOverview)
                    .font(.body)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .edgePadding()
    }

    @ContentBuilder
    var body: some View {
        Group {
            #if os(tvOS)
            Marquee(axis: .vertical, resetType: .loop, speed: 50, fade: 0) {
                content
            }
            #else
            ScrollView {
                content
            }
            .scrollIndicators(.hidden)
            #endif
        }
        .navigationTitle(item.displayTitle)
        .toolbarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
    }
}
