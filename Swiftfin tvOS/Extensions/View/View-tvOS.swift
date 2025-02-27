//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI
import SwiftUIIntrospect

extension View {

    @ViewBuilder
    func navigationBarBranding(
        isLoading: Bool = false
    ) -> some View {
        modifier(
            NavigationBarBrandingModifier(
                isLoading: isLoading
            )
        )
    }

    @ViewBuilder
    func leadingBarFilterDrawer<Filters: View>(@ViewBuilder _ filters: @escaping () -> Filters) -> some View {
        modifier(LeadingBarFilterDrawerModifier(filters: filters))
    }

    @ViewBuilder
    func leadingBarFilterDrawer(
        viewModel: FilterViewModel,
        types: [ItemFilterType],
        onSelect: @escaping (FilterCoordinator.Parameters) -> Void
    ) -> some View {
        if types.isEmpty {
            self
        } else {
            leadingBarFilterDrawer {
                LeadingBarFilterDrawer(
                    viewModel: viewModel,
                    types: types
                )
                .onSelect(onSelect)
            }
        }
    }
}
