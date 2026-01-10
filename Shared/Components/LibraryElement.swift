//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import JellyfinAPI
import SwiftUI

private let landscapeWidth: CGFloat = 110
private let portraitWidth: CGFloat = 60

protocol LibraryElement: Displayable, Poster {

    associatedtype GridBody: View = EmptyView
    associatedtype ListBody: View = EmptyView

    func libraryDidSelectElement(router: Router.Wrapper, in namespace: Namespace.ID)

    @MainActor
    @ViewBuilder
    func makeGridBody(libraryStyle: LibraryStyle) -> GridBody

    @MainActor
    @ViewBuilder
    func makeListBody(libraryStyle: LibraryStyle) -> ListBody

    static func layout(for libraryStyle: LibraryStyle) -> CollectionVGridLayout
}

extension LibraryElement {

    static func layout(for libraryStyle: LibraryStyle) -> CollectionVGridLayout {
        #if os(iOS)
        var padLayout: CollectionVGridLayout {
            switch (libraryStyle.posterDisplayType, libraryStyle.displayType) {
            case (.landscape, .grid):
                .minWidth(220)
            case (.portrait, .grid), (.square, .grid):
                .minWidth(140)
            case (_, .list):
                .columns(libraryStyle.listColumnCount, insets: .zero, itemSpacing: 0, lineSpacing: 0)
            }
        }

        var phoneLayout: CollectionVGridLayout {
            switch (libraryStyle.posterDisplayType, libraryStyle.displayType) {
            case (.landscape, .grid):
                .columns(2)
            case (.portrait, .grid):
                .columns(3)
            case (.square, .grid):
                .columns(3)
            case (_, .list):
                .columns(1, insets: .zero, itemSpacing: 0, lineSpacing: 0)
            }
        }

        return UIDevice.isPhone ? phoneLayout : padLayout
        #else
        var layout: CollectionVGridLayout {
            switch (libraryStyle.posterDisplayType, libraryStyle.displayType) {
            case (.landscape, .grid):
                return .columns(
                    5,
                    insets: EdgeInsets.edgeInsets,
                    itemSpacing: EdgeInsets.edgePadding,
                    lineSpacing: EdgeInsets.edgePadding
                )
            case (.portrait, .grid), (.square, .grid):
                return .columns(
                    7,
                    insets: EdgeInsets.edgeInsets,
                    itemSpacing: EdgeInsets.edgePadding,
                    lineSpacing: EdgeInsets.edgePadding
                )
            case (_, .list):
                return .columns(
                    libraryStyle.listColumnCount,
                    insets: EdgeInsets.edgeInsets,
                    itemSpacing: EdgeInsets.edgePadding,
                    lineSpacing: EdgeInsets.edgePadding
                )
            }
        }
        return layout
        #endif
    }
}
