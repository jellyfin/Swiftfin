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

struct FilterPickerBar: View {

    // MARK: - Observed Object

    @ObservedObject
    private var viewModel: FilterViewModel

    // MARK: - Filter Variables

    private var filterTypes: [ItemFilterType]
    private var onSelect: (FilterCoordinator.Parameters) -> Void

    // MARK: - Focus State

    @FocusState
    private var isFocused: Bool

    // MARK: - Longest Filter Width

    private var filterWidth: CGFloat {
        let longestFilter = filterTypes.map(\.displayTitle)
            .max(by: { $0.count < $1.count }) ?? ""

        return longestFilter.width(
            font: .footnote,
            weight: .semibold
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .leading) {

            if isFocused {
                selectedButtonBackground
                    .animation(.easeIn(duration: 0.2), value: isFocused)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            VStack(spacing: 20) {
                if viewModel.currentFilters.hasFilters {
                    FilterPickerButton(
                        systemName: "line.3.horizontal.decrease.circle.fill",
                        title: L10n.reset,
                        role: .destructive
                    )
                    .onSelect {
                        viewModel.send(.reset())
                    }
                    .environment(\.isSelected, true)
                } else {
                    // Leave space for the Reset Button
                    Spacer()
                        .frame(width: 75, height: 75)
                }

                ForEach(filterTypes, id: \.self) { type in
                    FilterPickerButton(
                        systemName: type.systemImage,
                        title: type.displayTitle
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
            .focused($isFocused)
            .padding(.horizontal, 0)
            .padding(.vertical, 1)
        }
    }

    private var selectedButtonBackground: some View {
        Rectangle()
            .fill(.regularMaterial)
            .brightness(-0.05)
            .frame(width: filterWidth + 200)
            .edgesIgnoringSafeArea(.leading)
            .edgesIgnoringSafeArea(.vertical)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(Color.secondarySystemFill)
                    .frame(width: 1)
                    .edgesIgnoringSafeArea(.leading)
                    .edgesIgnoringSafeArea(.vertical)
                    .padding(.trailing, 20)
            }
    }
}

extension FilterPickerBar {
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
