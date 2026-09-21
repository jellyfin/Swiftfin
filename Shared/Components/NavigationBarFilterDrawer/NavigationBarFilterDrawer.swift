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

    private enum FocusTarget: Hashable {
        case reset
        case filter(ItemFilterType)
    }

    @Default(.accentColor)
    private var accentColor

    @ObservedObject
    var viewModel: FilterViewModel

    @FocusState
    private var focusTarget: FocusTarget?

    @State
    private var lastFocusTarget: FocusTarget?

    @Router
    private var router

    let types: [ItemFilterType]

    private var preferredFocusTarget: FocusTarget? {
        switch lastFocusTarget {
        case .reset where viewModel.currentFilters.isNotEmpty:
            .reset
        case let .filter(type) where types.contains(type):
            .filter(type)
        default:
            types.first.map(FocusTarget.filter)
        }
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: UIDevice.isTV ? 25 : 5) {
                if viewModel.currentFilters.isNotEmpty {
                    StateAdapter(initialValue: false) { isPresentingConfirmation in
                        Button(L10n.reset, systemImage: "line.3.horizontal.decrease", role: .destructive) {
                            isPresentingConfirmation.wrappedValue = true
                        }
                        .focused($focusTarget, equals: .reset)
                        .foregroundStyle(.primary, .secondary)
                        .labelStyle(.iconOnly)
                        .confirmationDialog(
                            L10n.filters,
                            isPresented: isPresentingConfirmation,
                            titleVisibility: UIDevice.isTV ? .visible : .hidden
                        ) {
                            Button(L10n.reset, role: .destructive) {
                                viewModel.reset(filterType: nil)
                            }
                        }
                    }
                }

                ForEach(types, id: \.self) { type in
                    Button(type.displayTitle, systemImage: "chevron.down") {
                        router.route(
                            to: .filter(
                                type: type,
                                viewModel: viewModel
                            )
                        )
                    }
                    .focused($focusTarget, equals: .filter(type))
                    .foregroundStyle(.primary, .secondary)
                    .isSelected(viewModel.isFilterSelected(type: type))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, UIDevice.isTV ? 25 : 5)
            .controlSize(.small)
            .labelStyle(.trailingIcon)
            .buttonStyle(.capsule(selectionTint: accentColor))
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .focusSection()
        .defaultFocus(
            $focusTarget,
            preferredFocusTarget,
            priority: focusTarget == nil ? .userInitiated : .automatic
        )
        .onChange(of: focusTarget) { _, newValue in
            guard let newValue else { return }
            lastFocusTarget = newValue
        }
    }
}
