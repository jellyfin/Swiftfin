//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct FormItemSection<Item: Poster>: PlatformView {

    let item: Item

    var iOSView: some View {
        Section {
            HStack(alignment: .bottom, spacing: 12) {
                PosterImage(
                    item: item,
                    type: item.preferredPosterDisplayType,
                    contentMode: .fit
                )
                .frame(width: 100)
                .accessibilityIgnoresInvertColors()

                VStack(alignment: .leading) {
                    if let baseItem = item as? BaseItemDto, let parent = baseItem.parentTitle {
                        Text(parent)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Text(item.displayTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else if let baseItem = item as? BaseItemDto, let year = baseItem.productionYear {
                        Text(year.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom)
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(.zero)
        #if os(iOS)
            .listRowCornerRadius(0)
        #endif
    }

    var tvOSView: some View {
        Section(L10n.media) {
            if let baseItem = item as? BaseItemDto,
               let parentLabel = baseItem.parentLabel,
               let parentValue = baseItem.parentTitle
            {
                LabeledContent(
                    parentLabel,
                    value: parentValue
                )
            }

            LabeledContent(
                L10n.title,
                value: item.displayTitle
            )

            if let baseItem = item as? BaseItemDto,
               let subtitleLabel = baseItem.type?.displayTitle,
               let subtitleValue = baseItem.subtitle
            {
                LabeledContent(
                    subtitleLabel,
                    value: subtitleValue
                )
            } else if let baseItem = item as? BaseItemDto,
                      let year = baseItem.productionYear
            {
                LabeledContent(
                    L10n.year,
                    value: year.description
                )
            }
        }
        .labeledContentStyle(.focusable)
    }
}
