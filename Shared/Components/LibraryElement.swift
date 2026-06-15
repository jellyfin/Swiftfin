//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import SwiftUI

private let libraryListLandscapeWidth: CGFloat = 110
private let libraryListPortraitWidth: CGFloat = 60

@MainActor
protocol LibraryElement: Poster {

    associatedtype GridBody: View = DefaultLibraryGridElement<Self>
    associatedtype ListBody: View = DefaultLibraryListElement<Self>

    func libraryDidSelectElement(router: Router.Wrapper, in namespace: Namespace.ID)

    @ViewBuilder
    func makeGridBody(libraryStyle: LibraryStyle) -> GridBody

    @ViewBuilder
    func makeListBody(libraryStyle: LibraryStyle) -> ListBody

    static func layout(for libraryStyle: LibraryStyle) -> CollectionVGridLayout
}

extension LibraryElement {

    func makeGridBody(libraryStyle: LibraryStyle) -> DefaultLibraryGridElement<Self> {
        DefaultLibraryGridElement(element: self, libraryStyle: libraryStyle)
    }

    func makeListBody(libraryStyle: LibraryStyle) -> DefaultLibraryListElement<Self> {
        DefaultLibraryListElement(element: self, libraryStyle: libraryStyle)
    }

    static func layout(for libraryStyle: LibraryStyle) -> CollectionVGridLayout {
        #if os(iOS)
        let gridLayout: CollectionVGridLayout = {
            switch libraryStyle.posterDisplayType {
            case .landscape:
                .minWidth(220)
            case .portrait, .square:
                .minWidth(140)
            }
        }()

        let phoneGridLayout: CollectionVGridLayout = {
            switch libraryStyle.posterDisplayType {
            case .landscape:
                .columns(2)
            case .portrait, .square:
                .columns(3)
            }
        }()

        switch libraryStyle.displayType {
        case .grid:
            return UIDevice.isPhone ? phoneGridLayout : gridLayout
        case .list:
            return .columns(libraryStyle.listColumnCount, insets: .zero, itemSpacing: 0, lineSpacing: 0)
        }
        #else
        switch libraryStyle.displayType {
        case .grid:
            switch libraryStyle.posterDisplayType {
            case .landscape:
                return .columns(
                    5,
                    insets: EdgeInsets.edgeInsets,
                    itemSpacing: EdgeInsets.edgePadding,
                    lineSpacing: EdgeInsets.edgePadding
                )
            case .portrait, .square:
                return .columns(
                    7,
                    insets: EdgeInsets.edgeInsets,
                    itemSpacing: EdgeInsets.edgePadding,
                    lineSpacing: EdgeInsets.edgePadding
                )
            }
        case .list:
            return .columns(
                libraryStyle.listColumnCount,
                insets: EdgeInsets.edgeInsets,
                itemSpacing: EdgeInsets.edgePadding,
                lineSpacing: EdgeInsets.edgePadding
            )
        }
        #endif
    }
}

struct DefaultLibraryGridElement<Element: LibraryElement>: View {

    @Namespace
    private var namespace

    @Router
    private var router

    let element: Element
    let libraryStyle: LibraryStyle

    var body: some View {
        Button {
            element.libraryDidSelectElement(router: router, in: namespace)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                PosterImage(item: element, type: libraryStyle.posterDisplayType)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .posterStyle(libraryStyle.posterDisplayType)
                    .backport
                    .matchedTransitionSource(id: "item", in: namespace)
                    .posterShadow()

                if element.showTitle {
                    Text(element.displayTitle)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                        .lineLimit(1, reservesSpace: true)
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary, .secondary)
    }
}

struct DefaultLibraryListElement<Element: LibraryElement>: View {

    @Namespace
    private var namespace

    @Router
    private var router

    let element: Element
    let libraryStyle: LibraryStyle

    private var posterWidth: CGFloat {
        libraryStyle.posterDisplayType == .landscape ? libraryListLandscapeWidth : libraryListPortraitWidth
    }

    var body: some View {
        ListRow(insets: .init(vertical: 8, horizontal: EdgeInsets.edgePadding)) {
            PosterImage(item: element, type: libraryStyle.posterDisplayType)
                .posterStyle(libraryStyle.posterDisplayType)
                .frame(width: posterWidth)
                .backport
                .matchedTransitionSource(id: "item", in: namespace)
                .posterShadow()
        } content: {
            VStack(alignment: .leading, spacing: 5) {
                Text(element.displayTitle)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let subtitle = element.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } action: {
            element.libraryDidSelectElement(router: router, in: namespace)
        }
    }
}
