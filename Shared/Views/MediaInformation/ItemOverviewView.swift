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

    @Router
    private var router

    private let item: BaseItemDto

    init(item: BaseItemDto) {
        self.item = item
    }

    var body: some View {
        Form {
            FormItemSection(item: item)

            if let firstTagline = item.taglines?.first {
                Section(L10n.tagline) {
                    Button {} label: {
                        Text(firstTagline)
                            .foregroundStyle(Color.primary)
                    }
                }
            }

            Section(L10n.overview) {
                Button {} label: {
                    if let itemOverview = item.overview {
                        Text(itemOverview)
                            .foregroundStyle(Color.primary)
                    } else {
                        Text(L10n.noOverviewAvailable)
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        } image: {
            PosterImage(item: item, type: item.preferredPosterDisplayType)
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 400)
                .cornerRadius(16)
        }
        .navigationTitle(L10n.overview)
        .navigationBarCloseButton {
            router.dismiss()
        }
    }
}
