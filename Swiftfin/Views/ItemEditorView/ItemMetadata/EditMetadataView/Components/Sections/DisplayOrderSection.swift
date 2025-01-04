//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

extension EditMetadataView {

    struct DisplayOrderSection: View {

        @Binding
        var item: BaseItemDto

        let itemType: BaseItemKind

        var body: some View {
            Section(L10n.displayOrder) {
                switch itemType {
                case .boxSet:
                    Picker(
                        L10n.displayOrder,
                        selection: $item.displayOrder
                            .coalesce("")
                            .map(
                                getter: { BoxSetDisplayOrder(rawValue: $0) ?? .dateModified },
                                setter: { $0.rawValue }
                            )
                    ) {
                        ForEach(BoxSetDisplayOrder.allCases) { order in
                            Text(order.displayTitle).tag(order)
                        }
                    }

                case .series:
                    Picker(
                        L10n.displayOrder,
                        selection: $item.displayOrder
                            .coalesce("")
                            .map(
                                getter: { SeriesDisplayOrder(rawValue: $0) ?? .aired },
                                setter: { $0.rawValue }
                            )
                    ) {
                        ForEach(SeriesDisplayOrder.allCases) { order in
                            Text(order.displayTitle).tag(order)
                        }
                    }

                default:
                    EmptyView()
                }
            }
        }
    }
}
