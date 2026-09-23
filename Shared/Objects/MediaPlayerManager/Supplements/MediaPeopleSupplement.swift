//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import CollectionVGrid
import JellyfinAPI
import SwiftUI

@MainActor
struct MediaPeopleSupplement {

    let displayTitle: String = L10n.people
    let id: String = "People"
    let people: [BaseItemPerson]
}

extension MediaPeopleSupplement: VideoPlayerSupplement {

    var body: some View {
        PeopleOverlay(supplement: self)
    }

    private struct PeopleOverlay: PresentationView {

        @AdaptiveLayout
        private var viewLayout

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets: EdgeInsets

        @Environment(VideoPlayer.ViewState.self)
        private var viewState

        private var supplement: MediaPeopleSupplement

        init(supplement: MediaPeopleSupplement) {
            self.supplement = supplement
        }

        private var people: [BaseItemPerson] {
            supplement.people
        }

        var standardView: some View {
            CompactOrRegularView(
                isCompact: viewState.isCompact
            ) {
                compactView
            } regularView: {
                regularView
            }
        }

        private var compactView: some View {
            CollectionVGrid(
                uniqueElements: people,
                id: \.hashValue,
                layout: .columns(
                    1,
                    insets: .init(viewLayout.edgePadding),
                    itemSpacing: viewLayout.itemSpacing,
                    lineSpacing: viewLayout.itemSpacing
                )
            ) { person, _ in
                PersonRow(person: person)
            }
        }

        private func personView(for person: BaseItemPerson) -> some View {
            PosterButton(
                item: person,
                displayType: .portrait
            ) { _ in }
        }

        private var regularView: some View {
            CollectionHStack(
                uniqueElements: people,
                id: \.hashValue,
                layout: .minimumWidth(columnWidth: viewLayout.value(standard: 80, large: 150), rows: 1, columnFraction: 0.5)
            ) { person in
                personView(for: person)
            }
            .clipsToBounds(false)
            .insets(horizontal: max(safeAreaInsets.leading, safeAreaInsets.trailing, viewLayout.edgePadding))
            .itemSpacing(viewLayout.itemSpacing)
            .scrollBehavior(.continuousLeadingEdge)
            #if os(iOS)
            .contentInsetAdjustmentBehavior(.never)
            #endif
            .focusSection()
        }

        var largeView: some View {
            standardView
        }
    }

    private struct PersonContent: View {

        let person: BaseItemPerson

        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                Text(person.displayTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                if let role = person.displayRole {
                    Text(role)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private struct PersonRow: View {

        @AdaptiveLayout
        private var viewLayout

        let person: BaseItemPerson

        var body: some View {
            ListRow(insets: .init(horizontal: viewLayout.edgePadding)) {
                PosterImage(
                    item: person,
                    type: .portrait,
                    size: .extraSmall,
                    contentMode: .fit
                )
                .frame(height: 90)
                .padding(.vertical, 8)
            } content: {
                PersonContent(person: person)
            }
        }
    }
}
