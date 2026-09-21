//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct FilterBar: View {

    private enum FocusTarget: Hashable {
        case reset
        case filter(ItemFilterType)
    }

    @Default(.accentColor)
    private var accentColor

    @FocusState
    private var focusTarget: FocusTarget?

    @ObservedObject
    var viewModel: FilterViewModel

    @Router
    private var router

    @State
    private var lastFocusTarget: FocusTarget?

    let types: [ItemFilterType]
    let edge: HorizontalEdge

    private let buttonSize: CGFloat = 68

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

    @ViewBuilder
    private func button(
        _ title: String,
        systemImage: String,
        target: FocusTarget,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Color.clear
            .frame(width: buttonSize, height: buttonSize)
            .overlay(alignment: edge == .leading ? .leading : .trailing) {
                Button(action: action) {
                    HStack(spacing: 12) {
                        if focusTarget == target, edge == .trailing {
                            Text(title)
                                .transition(.opacity)
                        }

                        Image(systemName: systemImage)
                            .frame(width: buttonSize - 32, height: buttonSize - 16)

                        if focusTarget == target, edge == .leading {
                            Text(title)
                                .transition(.opacity)
                        }
                    }
                    .lineLimit(1)
                }
                .focused($focusTarget, equals: target)
                .isSelected(isSelected)
                .accessibilityLabel(title)
                .fixedSize()
            }
            .zIndex(focusTarget == target ? 1 : 0)
    }

    var body: some View {
        VStack(spacing: 20) {
            if viewModel.currentFilters.isNotEmpty {
                button(
                    L10n.reset,
                    systemImage: "line.3.horizontal.decrease",
                    target: .reset,
                    isSelected: true
                ) {
                    viewModel.reset(filterType: nil)
                }
            }

            ForEach(types, id: \.self) { type in
                button(
                    type.displayTitle,
                    systemImage: type.systemImage,
                    target: .filter(type),
                    isSelected: viewModel.isFilterSelected(type: type)
                ) {
                    router.route(
                        to: .filter(
                            type: type,
                            viewModel: viewModel
                        )
                    )
                }
            }
        }
        .font(.callout)
        .controlSize(.large)
        .buttonStyle(.capsule(selectionTint: accentColor))
        .animation(.snappy(duration: 0.2), value: focusTarget)
        .scrollIfLargerThanContainer()
        .frame(width: buttonSize)
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
