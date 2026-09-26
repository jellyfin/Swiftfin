//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import SwiftUI

// TODO: Make an Environemnt?
//       - for libraryStyle, action, etc.

@MainActor
protocol LibraryElement: Displayable, Hashable, Identifiable {

    associatedtype Body: View

    static var supportedLibraryStyleOptions: LibraryStyleOptions { get }

    var supportedLibraryStyleOptions: LibraryStyleOptions { get }

    func libraryDidSelectElement(
        router: Router.Wrapper,
        in namespace: Namespace.ID
    )

    @ViewBuilder
    func makeBody(
        libraryStyle: LibraryStyle,
        action: (() -> Void)?
    ) -> Body

    static func layout(
        for libraryStyle: LibraryStyle,
        options: LibraryStyleOptions,
        insets: EdgeInsets
    ) -> CollectionVGridLayout
}

extension LibraryElement {

    static var supportedLibraryStyleOptions: LibraryStyleOptions {
        .init(
            displayTypes: [.list],
            posterDisplayTypes: [.portrait],
            fallbackPosterDisplayType: .portrait
        )
    }

    var supportedLibraryStyleOptions: LibraryStyleOptions {
        Self.supportedLibraryStyleOptions
    }

    func resolvedLibraryStyle(_ libraryStyle: LibraryStyle) -> LibraryStyle {
        supportedLibraryStyleOptions.normalized(libraryStyle)
    }

    func libraryDidSelectElement(router: Router.Wrapper, in namespace: Namespace.ID) {}

    @ViewBuilder
    func makeBody(libraryStyle: LibraryStyle) -> Body {
        makeBody(libraryStyle: libraryStyle, action: nil)
    }

    static func layout(
        for libraryStyle: LibraryStyle,
        options: LibraryStyleOptions,
        insets: EdgeInsets
    ) -> CollectionVGridLayout {
        let libraryStyle = options.normalized(libraryStyle)

        #if os(iOS)
        switch libraryStyle.displayType {
        case .grid:
            if UIDevice.isPhone {
                return .columns(
                    libraryStyle.posterDisplayType == .landscape ? 2 : 3,
                    insets: insets,
                    itemSpacing: EdgeInsets.itemSpacing,
                    lineSpacing: EdgeInsets.itemSpacing
                )
            }

            return .minWidth(
                libraryStyle.posterDisplayType == .landscape ? 220 : 140,
                insets: insets,
                itemSpacing: EdgeInsets.itemSpacing,
                lineSpacing: EdgeInsets.itemSpacing
            )
        case .list:
            return .columns(
                libraryStyle.listColumnCount,
                insets: insets,
                itemSpacing: 0,
                lineSpacing: 0
            )
        }
        #else
        let columnCount = switch libraryStyle.displayType {
        case .grid:
            libraryStyle.posterDisplayType == .landscape ? 4 : 7
        case .list:
            libraryStyle.listColumnCount
        }

        return .columns(
            columnCount,
            insets: insets,
            itemSpacing: EdgeInsets.itemSpacing,
            lineSpacing: EdgeInsets.itemSpacing
        )
        #endif
    }
}
