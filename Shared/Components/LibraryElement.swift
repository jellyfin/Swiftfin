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
        insets: EdgeInsets,
        viewLayout: ViewLayout
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

    func makeBody(libraryStyle: LibraryStyle) -> Body {
        // By default, have conformers determine action
        // internally for navigation with their namespace
        makeBody(libraryStyle: libraryStyle, action: nil)
    }

    static func layout(
        for libraryStyle: LibraryStyle,
        options: LibraryStyleOptions,
        insets: EdgeInsets,
        viewLayout: ViewLayout
    ) -> CollectionVGridLayout {
        let libraryStyle = options.normalized(libraryStyle)

        switch libraryStyle.displayType {
        case .grid:
            return .minWidth(
                viewLayout.value(
                    standard: viewLayout.posterMinimumWidth(for: libraryStyle.posterDisplayType),
                    large: libraryStyle.posterDisplayType == .landscape ? 350 : 220
                ),
                insets: insets,
                itemSpacing: viewLayout.itemSpacing,
                lineSpacing: viewLayout.itemSpacing
            )

        case .list:
            // Keep the saved preference as an upper bound so it returns in wider windows.
            let columns = viewLayout.libraryListColumns(maximumCount: libraryStyle.listColumnCount)
            return .columns(
                columns.count(for: viewLayout.size.width - insets.leading - insets.trailing),
                insets: insets,
                itemSpacing: columns.spacing,
                lineSpacing: columns.spacing,
                itemSizing: .height
            )
        }
    }
}
