//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct CompactPortraitHeaderContentGroup: ContentGroup {

        let id: String = "itemView-header"
        let provider: ItemContentGroupProvider

        func body(with viewModel: Empty) -> Body {
            Body(provider: provider)
        }

        struct Body: View {

            @ObservedObject
            var provider: ItemContentGroupProvider

            var body: some View {
                VStack(spacing: 10) {
                    VStack(spacing: 10) {
                        HStack(alignment: .bottom, spacing: 12) {
                            PosterImage(
                                item: provider.item,
                                type: .portrait,
                                contentMode: .fit
                            )
                            .frame(width: 130)
                            .subtleShadow()

                            Text(provider.item.displayTitle)
                                .font(.title2)
                                .lineLimit(4)
                                .fontWeight(.semibold)
                                .padding(.bottom, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        ItemView.ActionButtonHStack(provider: provider)
                    }
                    .frame(maxWidth: 300)

                    Divider()

                    ItemView.Description(item: provider.item)
                }
                .edgePadding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
