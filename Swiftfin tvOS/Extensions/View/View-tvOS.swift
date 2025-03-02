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
    func libraryFilterBars<Filters: View, Letters: View>(
        @ViewBuilder filters: @escaping () -> Filters,
        @ViewBuilder letters: @escaping () -> Letters
    ) -> some View {
        modifier(LibraryFilterModifier(filters: filters, letters: letters))
    }

    @ViewBuilder
    func libraryFilterBars(
        viewModel: FilterViewModel,
        letterPicker: Bool = false,
        types: [ItemFilterType],
        onSelect: @escaping (FilterCoordinator.Parameters) -> Void
    ) -> some View {
        if types.isEmpty {
            self
        } else {
            libraryFilterBars(
                filters: {
                    FilterPickerBar(
                        viewModel: viewModel,
                        types: types
                    )
                    .onSelect(onSelect)
                },
                letters: {
                    if letterPicker {
                        LetterPickerBar(viewModel: viewModel)
                    } else {
                        EmptyView()
                    }
                }
            )
        }
    }
}
