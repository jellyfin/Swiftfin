//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

private let baseItemPersonListWidth: CGFloat = 60

extension BaseItemPerson: LibraryElement {

    static var supportedLibraryStyleOptions: LibraryStyleOptions {
        BaseItemKind.libraryStyleOptions(for: [.person])
    }

    func libraryDidSelectElement(
        router: Router.Wrapper,
        in namespace: Namespace.ID
    ) {
        BaseItemDto(person: self)
            .libraryDidSelectElement(router: router, in: namespace)
    }

    @ViewBuilder
    func makeBody(
        libraryStyle: LibraryStyle,
        action: (() -> Void)?
    ) -> some View {
        switch libraryStyle.displayType {
        case .grid:
            BaseItemPersonLibraryGridElement(
                person: self,
                libraryStyle: libraryStyle
            )
        case .list:
            BaseItemPersonLibraryListElement(
                person: self,
                libraryStyle: libraryStyle,
                action: action
            )
        }
    }
}

private struct BaseItemPersonLibraryGridElement: View {

    @Namespace
    private var namespace

    @Router
    private var router

    let person: BaseItemPerson
    let libraryStyle: LibraryStyle

    private var resolvedLibraryStyle: LibraryStyle {
        person.resolvedLibraryStyle(libraryStyle)
    }

    var body: some View {
        Button {
            person.libraryDidSelectElement(router: router, in: namespace)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                PosterImage(item: person, type: resolvedLibraryStyle.posterDisplayType)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .posterStyle(resolvedLibraryStyle.posterDisplayType)
                    .backport
                    .matchedTransitionSource(id: "item", in: namespace)
                    .posterShadow()

                VStack(alignment: .leading, spacing: 0) {
                    Text(person.displayTitle)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                        .lineLimit(1, reservesSpace: true)

                    Text(person.subtitle ?? " ")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .lineLimit(1, reservesSpace: true)
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary, .secondary)
    }
}

struct BaseItemPersonLibraryListElement: View {

    @Environment(\.isEditing)
    private var isEditing
    @Environment(\.isSelected)
    private var isSelected

    @Namespace
    private var namespace

    @Router
    private var router

    let person: BaseItemPerson
    let libraryStyle: LibraryStyle
    var action: (() -> Void)?

    var body: some View {
        ListRow(insets: .init(vertical: 8, horizontal: EdgeInsets.edgePadding)) {
            PosterImage(
                item: person,
                type: person.resolvedLibraryStyle(libraryStyle).posterDisplayType,
                size: .extraSmall
            )
            .posterStyle(person.resolvedLibraryStyle(libraryStyle).posterDisplayType)
            .frame(width: baseItemPersonListWidth)
            .backport
            .matchedTransitionSource(id: "item", in: namespace)
            .posterShadow()
        } content: {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(person.displayTitle)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let subtitle = person.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isEditing {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                }
            }
        } action: {
            if let action {
                action()
            } else {
                person.libraryDidSelectElement(router: router, in: namespace)
            }
        }
    }
}
