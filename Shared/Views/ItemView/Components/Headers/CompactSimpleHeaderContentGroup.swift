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

    struct CompactSimpleHeaderContentGroup: ContentGroup {

        let id: String = "itemView-header"
        let provider: ItemContentGroupProvider

        func body(with viewModel: Empty) -> Body {
            Body(provider: provider)
        }

        struct Body: View {

            @ObservedObject
            var provider: ItemContentGroupProvider

            @StoredValue(.User.itemViewAttributes)
            private var attributes

            private var headerImageDisplayType: PosterDisplayType {
                provider.item.preferredPosterDisplayType == .portrait ? .landscape : provider.item.preferredPosterDisplayType
            }

            @ViewBuilder
            private var content: some View {
                PosterImage(
                    item: provider.item,
                    type: headerImageDisplayType,
                    contentMode: .fit
                )
                .frame(maxWidth: headerImageDisplayType == .square ? 400 : .infinity)
                .subtleShadow()

                VStack(alignment: .center, spacing: 5) {
                    if let parentID = provider.item.parentRootID, let parentTitle = provider.item.parentTitle {
                        ParentButton(title: parentTitle, id: parentID)
                    }

                    Text(provider.item.displayTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    MetadataHStack(item: provider.item)
                }
            }

            @ViewBuilder
            private var peopleContent: some View {
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
                .frame(maxWidth: 300)
            }

            var body: some View {
                VStack(spacing: 10) {
                    switch provider.item.type {
                    case .person, .musicArtist:
                        peopleContent
                    default:
                        content
                    }

                    VStack(alignment: .center, spacing: 5) {
                        if provider.item.presentPlayButton {
                            PlayButton(provider: provider)
                        }

                        ItemView.ActionButtonHStack(provider: provider)
                    }
                    .frame(maxWidth: 300)

                    Divider()

                    ItemView.Description(item: provider.item)

                    ItemView.AttributesHStack(
                        attributes: attributes,
                        item: provider.item,
                        selectedMediaSource: provider.mediaPlayerItemProvider?.mediaSource,
                        alignment: .leading
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.secondary)
                }
                .edgePadding()
                .frame(maxWidth: .infinity)
            }
        }
    }
}
