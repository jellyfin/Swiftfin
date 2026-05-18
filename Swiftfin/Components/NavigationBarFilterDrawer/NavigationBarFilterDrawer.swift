//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct NavigationBarFilterDrawer: View {

    @ObservedObject
    var viewModel: FilterViewModel

    @Router
    private var router

    let types: [ItemFilterType]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                if viewModel.currentFilters.isNotEmpty {
                    Menu(L10n.reset, systemImage: "line.3.horizontal.decrease") {
                        Button(L10n.reset, role: .destructive) {
                            viewModel.reset(filterType: nil)
                        }
                    }
                    .foregroundStyle(.primary, .secondary)
                    .labelStyle(NavigationDrawerLabelStyle(isIconOnly: true))
                }

                ForEach(types, id: \.self) { type in
                    Button {
                        router.route(
                            to: .filter(
                                type: type,
                                viewModel: viewModel
                            )
                        )
                    } label: {
                        Label {
                            Text(type.displayTitle)
                        } icon: {
                            EmptyView()
                        }
                    }
                    .foregroundStyle(.primary, .secondary)
                    .isHighlighted(viewModel.isFilterSelected(type: type))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 5)
            .labelStyle(NavigationDrawerLabelStyle())
        }
    }
}
