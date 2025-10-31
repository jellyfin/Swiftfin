//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

private let landscapeWidth: CGFloat = 110
private let portraitWidth: CGFloat = 60

struct LibraryRow<Element: Poster>: View {

    @Namespace
    private var namespace

    private let item: Element
    private var action: (Namespace.ID) -> Void
    private let posterType: PosterDisplayType

    init(
        item: Element,
        posterType: PosterDisplayType,
        action: @escaping (Namespace.ID) -> Void
    ) {
        self.item = item
        self.action = action
        self.posterType = posterType
    }

    @ViewBuilder
    private func itemAccessoryView(item: BaseItemDto) -> some View {
        DotHStack {
            if item.type == .episode, let seasonEpisodeLocator = item.seasonEpisodeLabel {
                Text(seasonEpisodeLocator)
            } else if let premiereYear = item.premiereDateYear {
                Text(premiereYear)
            }

            if let runtime = item.runTimeLabel {
                Text(runtime)
            }

            if let officialRating = item.officialRating {
                Text(officialRating)
            }
        }
    }

    @ViewBuilder
    private func personAccessoryView(person: BaseItemPerson) -> some View {
        if let subtitle = person.subtitle {
            Text(subtitle)
        }
    }

    @ViewBuilder
    private var accessoryView: some View {
        switch item {
        case let element as BaseItemDto:
            itemAccessoryView(item: element)
        case let element as BaseItemPerson:
            personAccessoryView(person: element)
        default:
            AssertionFailureView("Used an unexpected type within a `PagingLibaryView`?")
        }
    }

    @ViewBuilder
    private var rowContent: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(item.displayTitle)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            accessoryView
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var rowLeading: some View {
        PosterImage(
            item: item,
            type: posterType,
            contentMode: .fill
        )
        .posterShadow()
        .frame(width: posterType == .landscape ? landscapeWidth : portraitWidth)
        .padding(.vertical, 8)
    }

    // MARK: body

    var body: some View {
        ListRow(insets: .init(horizontal: EdgeInsets.edgePadding)) {
            action(namespace)
        } leading: {
            rowLeading
        } content: {
            rowContent
        }
        .backport
        .matchedTransitionSource(id: "item", in: namespace)
    }
}
