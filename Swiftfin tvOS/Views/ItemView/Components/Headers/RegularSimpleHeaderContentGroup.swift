//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: fix header focus not default

extension ItemView {

    struct RegularSimpleHeaderContentGroup: ContentGroup {

        let id: String = "itemView-header"
        let provider: ItemContentGroupProvider

        func body(with viewModel: Empty) -> Body {
            Body(provider: provider)
        }

        struct Body: View {

            @FocusState
            private var isPlayButtonFocused: Bool

            @ObservedObject
            var provider: ItemContentGroupProvider

            @StoredValue(.User.itemViewAttributes)
            private var attributes

            private var canFocusPlayButton: Bool {
                provider.item.presentPlayButton && provider.selectedMediaSource != nil
            }

            private var posterDisplayType: PosterDisplayType {
                provider.item.type == .person ? .portrait : .landscape
            }

            @ViewBuilder
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
                    imageAspectRatio: posterDisplayType == .landscape ? 1.77 : 1,
                    imageColumnFraction: posterDisplayType == .landscape ? 0.5 : 0.33,
                    spacing: EdgeInsets.edgePadding
                ) {
                    PosterImage(
                        item: provider.item,
                        type: posterDisplayType,
                        size: .medium,
                        contentMode: .fit
                    )
                    .posterBorder()
                    .posterCornerRadius(posterDisplayType)
                    .subtleShadow()
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .trailing
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        title

                        ItemView.Description(item: provider.item)

                        VStack(alignment: .leading, spacing: 25) {
                            if provider.item.presentPlayButton {
                                PlayButton(
                                    provider: provider,
                                    playButtonFocus: $isPlayButtonFocused
                                )
                            }

                            ItemView.ActionButtonHStack(provider: provider)
                        }
                        .frame(maxWidth: 450, alignment: .leading)
                        .padding(.bottom, 15)

                        ItemView.AttributesHStack(
                            attributes: attributes,
                            item: provider.item,
                            selectedMediaSource: provider.selectedMediaSource,
                            alignment: .leading
                        )
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .focusSection()
                .if(canFocusPlayButton) { view in
                    view
                        .backport
                        .defaultFocus(
                            $isPlayButtonFocused,
                            true,
                            priority: .userInitiated
                        )
                }
                .edgePadding()
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }
}
