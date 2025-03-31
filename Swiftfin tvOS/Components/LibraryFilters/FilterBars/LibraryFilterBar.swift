//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct LibraryFilterBar: View {

    // MARK: - ObservedObject

    @ObservedObject
    private var viewModel: FilterViewModel

    // MARK: - Filter Variables

    private var filterTypes: [ItemFilterType]
    private var onSelect: (FilterCoordinator.Parameters) -> Void

    // MARK: - Focus State

    @FocusState
    private var isFocused: Bool
    @FocusState
    private var resetButtonFocused: Bool

    // MARK: - FilterWidth

    private var filterWidth: CGFloat {
        let longestFilterString = filterTypes.map(\.displayTitle)
            .max(by: { $0.count < $1.count }) ?? ""

        return longestFilterString.width(
            font: .footnote,
            weight: .semibold
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .leading) {
            if isFocused || resetButtonFocused {
                selectedButtonBackground
                    .animation(.easeIn(duration: 0.2), value: isFocused || resetButtonFocused)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            VStack(alignment: .leading, spacing: 20) {
                if viewModel.currentFilters.hasFilters {
                    FilterButton(
                        systemName: "line.3.horizontal.decrease.circle.fill",
                        title: L10n.reset,
                        maxWidth: filterWidth + 120,
                        role: .destructive
                    )
                    .onSelect {
                        viewModel.send(.reset())
                    }
                    .environment(\.isSelected, true)
                    .focused($resetButtonFocused, equals: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                ForEach(filterTypes, id: \.self) { type in
                    FilterButton(
                        systemName: type.systemImage,
                        title: type.displayTitle,
                        maxWidth: filterWidth + 120
                    )
                    .onSelect {
                        onSelect(.init(type: type, viewModel: viewModel))
                    }
                    .environment(
                        \.isSelected,
                        viewModel.isFilterSelected(type: type)
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .focused($isFocused)
            .padding(.horizontal, 20)
            .padding(.vertical, 1)
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentFilters.hasFilters)
        }
        .frame(width: filterWidth + 170)
    }

    // MARK: - Selected Button Background

    private var selectedButtonBackground: some View {
        Rectangle()
            .fill(.regularMaterial)
            .brightness(-0.05)
            .frame(width: filterWidth + 170)
            .edgesIgnoringSafeArea(.leading)
            .edgesIgnoringSafeArea(.vertical)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(Color.secondarySystemFill)
                    .frame(width: 1)
                    .edgesIgnoringSafeArea(.leading)
                    .edgesIgnoringSafeArea(.vertical)
            }
    }
}

extension LibraryFilterBar {
    init(viewModel: FilterViewModel, types: [ItemFilterType]) {
        self.init(
            viewModel: viewModel,
            filterTypes: types,
            onSelect: { _ in }
        )
    }

    func onSelect(_ action: @escaping (FilterCoordinator.Parameters) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
