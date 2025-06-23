//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import JellyfinAPI
import SwiftUI

extension ItemView {

    struct PersonItemContentView: View {

        @Router
        private var router

        @ObservedObject
        var viewModel: PersonItemViewModel

        var body: some View {
            SeparatorVStack(alignment: .leading) {
                RowDivider()
                    .padding(.vertical, 10)
            } content: {

                // MARK: - Items

                ForEach(viewModel.personItems.elements, id: \.key) { element in
                    if element.value.isNotEmpty {
                        PosterHStack(
                            title: element.key.pluralDisplayTitle,
                            type: .portrait,
                            items: element.value
                        )
                        .trailing {
                            SeeAllButton()
                                .onSelect {
                                    let viewModel = ItemLibraryViewModel(
                                        title: viewModel.item.displayTitle,
                                        id: viewModel.item.id,
                                        element.value
                                    )
                                    router.route(to: .library(viewModel: viewModel))
                                }
                        }
                        .onSelect { item in
                            router.route(to: .item(item: item))
                        }
                    }
                }

                ItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}
