//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import SwiftUI

struct PosterHStack<
    Data: Collection
>: View where Data.Element: Poster, Data.Index == Int {

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @State
    private var availableWidth: CGFloat = 0
    @State
    private var leadingElementID: Data.Element.ID?

    let elements: Data
    let displayType: PosterDisplayType
    let size: PosterDisplayType.Size
    let action: (Data.Element, Namespace.ID) -> Void

    private var layout: CollectionHStackLayout {
        #if os(tvOS)
        .grid(
            columns: displayType == .landscape ? 5 : 7,
            rows: 1,
            columnTrailingInset: 0
        )
        #else
        if horizontalSizeClass == .regular {
            let minWidth: CGFloat = {
                switch (displayType, size) {
                case (.landscape, .small):
                    220
                case (.landscape, .medium):
                    260
                case (_, .small):
                    140
//                case (_, .medium):
                default:
                    200
                }
            }()

            return .minimumWidth(
                columnWidth: minWidth,
                rows: 1
            )
        } else {
            let columnCount: CGFloat = {
                switch (displayType, size) {
                case (.landscape, .small):
                    2
                case (.landscape, .medium):
                    1.5
                case (_, .small):
                    3
//                case (_, .medium):
                default:
                    2
                }
            }()

            return .grid(
                columns: columnCount,
                rows: 1,
                columnTrailingInset: 0
            )
        }
        #endif
    }

    var body: some View {
        CollectionHStack(
            uniqueElements: elements,
            layout: layout
        ) { item in
            PosterButton(
                item: item,
                displayType: displayType,
                size: size
            ) { namespace in
                action(item, namespace)
            }
        }
        .clipsToBounds(false)
        .insets(horizontal: EdgeInsets.edgePadding)
        .itemSpacing(EdgeInsets.itemSpacing)
        .scrollBehavior(.continuousLeadingEdge)
        .initialElement(id: leadingElementID)
        .alignedLeadingElement(id: $leadingElementID)
        // Recreate only the collection, retaining the loaded media and scroll anchor.
        // Avoid reusing snapshot and sizing state across scene-width transitions.
        .id(availableWidth)
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.width
        } action: { width in
            guard width.isFinite, width > 0 else { return }

            availableWidth = width
        }
        .withViewContext(.isThumb)
    }
}
