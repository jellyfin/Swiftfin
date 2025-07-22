//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import JellyfinAPI
import OrderedCollections
import SwiftUI

// TODO: consolidate `ItemTypCollection` stacks
//       - Show show name in episode subheader
//       - CollectionItemContentView

extension ItemView {

    struct PersonItemContentView: View {

        typealias Element = OrderedDictionary<BaseItemKind, ItemLibraryViewModel>.Elements.Element

        @Router
        private var router

        @ObservedObject
        var viewModel: CollectionItemViewModel

        var body: some View {
            SeparatorVStack(alignment: .leading) {
                RowDivider()
                    .padding(.vertical, 10)
            } content: {

                // MARK: - Items

                ForEach(
                    viewModel.sections.elements,
                    id: \.key
                ) { element in
                    ItemTypeCollectionHStack(element: element)
                }

                ItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}
