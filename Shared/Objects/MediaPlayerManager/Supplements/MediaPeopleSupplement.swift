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

class MediaPeopleSupplement: ObservableObject, MediaPlayerSupplement {

    let people: [BaseItemPerson]
    let displayTitle: String = L10n.people
    let id: String = "People"

    init(people: [BaseItemPerson]) {
        self.people = people
    }

    var videoPlayerBody: some PlatformView {
        PeopleOverlay(supplement: self)
    }
}

extension MediaPeopleSupplement {

    private struct PeopleOverlay: PlatformView {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets: EdgeInsets

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState

        @ObservedObject
        private var supplement: MediaPeopleSupplement

        init(supplement: MediaPeopleSupplement) {
            self.supplement = supplement
        }

        private var people: [BaseItemPerson] {
            supplement.people
        }

        var iOSView: some View {
            CompactOrRegularView(
                isCompact: containerState.isCompact
            ) {
                iOSCompactView
            } regularView: {
                iOSRegularView
            }
        }

        @ViewBuilder
        private var iOSCompactView: some View {
            CollectionVGrid(
                uniqueElements: people,
                id: \.hashValue,
                layout: .columns(
                    1,
                    insets: .init(EdgeInsets.edgePadding),
                    itemSpacing: EdgeInsets.itemSpacing,
                    lineSpacing: EdgeInsets.itemSpacing
                )
            ) { person, _ in
                PersonRow(person: person)
            }
        }

        @ViewBuilder
        private func personView(for person: BaseItemPerson) -> some View {
            PosterButton(
                item: person,
                displayType: .portrait
            ) { _ in }
        }

        @ViewBuilder
        private var iOSRegularView: some View {
            CollectionHStack(
                uniqueElements: people,
                id: \.hashValue,
                layout: .minimumWidth(columnWidth: 80, rows: 1)
            ) { person in
                personView(for: person)
            }
            .clipsToBounds(false)
            .insets(horizontal: max(safeAreaInsets.leading, safeAreaInsets.trailing) + EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.itemSpacing)
            .scrollBehavior(.continuousLeadingEdge)
        }

        var tvOSView: some View {
            CollectionHStack(
                uniqueElements: people,
                id: \.hashValue,
                layout: .grid(columns: 10, rows: 1, columnTrailingInset: 0)
            ) { person in
                personView(for: person)
            }
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.itemSpacing)
            .ignoresSafeArea(.container, edges: .horizontal)
            .frame(maxHeight: .infinity)
            .focusSection()
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

        let person: BaseItemPerson

        var body: some View {
            ListRow(insets: .init(horizontal: EdgeInsets.edgePadding)) {
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
