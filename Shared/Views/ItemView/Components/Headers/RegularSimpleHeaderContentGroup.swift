//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct RegularSimpleHeaderContentGroup: ContentGroup {

        let id: String = ItemView.Component.header
        let provider: ItemContentGroupProvider

        func body(with viewModel: Empty) -> Body {
            Body(provider: provider)
        }

        struct Body: View {

            @AdaptiveLayout
            private var viewLayout

            @ObservedObject
            var provider: ItemContentGroupProvider

            @StoredValue(.User.itemViewAttributes)
            private var attributes

            private var posterDisplayType: PosterDisplayType {
                provider.item.type == .person ? .portrait : .landscape
            }

            private var title: some View {
                VStack(alignment: .leading, spacing: 5) {
                    if let parentID = provider.item.parentRootID, let parentTitle = provider.item.parentTitle {
                        ParentButton(title: parentTitle, id: parentID)
                    }

                    Text(provider.item.displayTitle)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    MetadataHStack(item: provider.item)
                }
            }

            var body: some View {
                ImageContentColumnsLayout(
                    idealContentWidth: 600,
                    imageAspectRatio: posterDisplayType == .landscape ? 1.77 : 2.0 / 3.0,
                    imageColumnFraction: posterDisplayType == .landscape ? 0.5 : 0.33,
                    spacing: viewLayout.edgePadding
                ) {
                    PosterImage(
                        item: provider.item,
                        type: posterDisplayType,
                        size: .medium,
                        contentMode: .fit
                    )
                    .if(viewLayout.isLarge) { poster in
                        poster
                            .posterBorder()
                            .posterCornerRadius(posterDisplayType)
                            .subtleShadow()
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .trailing
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        title

                        ItemView.Description(item: provider.item)

                        ItemView.ActionBar(
                            provider: provider,
                            alignment: .leading
                        )
                        .frame(maxWidth: viewLayout.value(standard: 300, large: 450), alignment: .leading)
                        .if(viewLayout.isLarge) { buttons in
                            buttons
                                .padding(.vertical)
                        }

                        ItemView.AttributesHStack(
                            attributes: attributes,
                            item: provider.item,
                            selectedMediaSource: provider.playbackIntent?.mediaSource,
                            alignment: .leading
                        )
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .focusSection()
                .edgePadding()
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }
}
