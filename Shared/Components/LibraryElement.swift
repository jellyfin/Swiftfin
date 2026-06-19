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
        options: LibraryStyleOptions
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
        options: LibraryStyleOptions
    ) -> CollectionVGridLayout {
        let libraryStyle = options.normalized(libraryStyle)

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
                    4,
                    insets: .init(vertical: 0, horizontal: EdgeInsets.edgePadding),
                    itemSpacing: EdgeInsets.edgePadding,
                    lineSpacing: EdgeInsets.edgePadding
                )
            case .portrait, .square:
                return .columns(
                    7,
                    insets: .init(vertical: 0, horizontal: EdgeInsets.edgePadding),
                    itemSpacing: EdgeInsets.edgePadding,
                    lineSpacing: EdgeInsets.edgePadding
                )
            }
        case .list:
            return .columns(
                libraryStyle.listColumnCount,
                insets: .init(vertical: 0, horizontal: EdgeInsets.edgePadding),
                itemSpacing: EdgeInsets.edgePadding,
                lineSpacing: EdgeInsets.edgePadding
            )
        }
        #endif
    }
}
