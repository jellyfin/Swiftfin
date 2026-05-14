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
                layout: .columns(
                    1,
                    insets: .init(top: 0, leading: 0, bottom: EdgeInsets.edgePadding, trailing: 0)
                )
            ) { person, _ in
                PersonRow(person: person)
                    .edgePadding(.horizontal)
            }
        }

        @ViewBuilder
        private func personView(for person: BaseItemPerson) -> some View {
            #if os(iOS)
            PosterButton(
                item: person,
                type: .portrait
            ) { _ in
            } label: {
                TitleSubtitleContentView(
                    title: person.displayTitle,
                    subtitle: person.firstRole ?? ""
                )
            }
            #else
            PosterButton(
                item: person,
                type: .portrait
            ) { _ in
            } label: {
                TitleSubtitleContentView(
                    title: person.displayTitle,
                    subtitle: person.firstRole ?? ""
                )
            }
            #endif
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
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .scrollBehavior(.continuousLeadingEdge)
        }

        var tvOSView: some View {
            CollectionHStack(
                uniqueElements: people,
                id: \.hashValue,
                columns: 7
            ) { person in
                personView(for: person)
            }
            .clipsToBounds(false)
            .insets(horizontal: max(safeAreaInsets.leading, safeAreaInsets.trailing) + EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding - 20)
            .scrollBehavior(.continuousLeadingEdge)
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

                if let role = person.firstRole {
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
            ListRow(insets: .init(horizontal: EdgeInsets.edgePadding), action: {}) {
                PosterImage(
                    item: person,
                    type: .portrait,
                    contentMode: .fit,
                    maxWidth: 60
                )
                .frame(height: 90)
                .padding(.vertical, 8)
            } content: {
                PersonContent(person: person)
            }
        }
    }
}
