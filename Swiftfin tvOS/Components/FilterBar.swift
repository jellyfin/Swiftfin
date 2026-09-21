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
    let orientation: Axis
    var edge: HorizontalEdge = .trailing

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
    private func verticalButton(
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

    @ViewBuilder
    private var verticalBar: some View {
        VStack(spacing: 20) {
            if viewModel.currentFilters.isNotEmpty {
                verticalButton(
                    L10n.reset,
                    systemImage: "line.3.horizontal.decrease",
                    target: .reset,
                    isSelected: true
                ) {
                    viewModel.reset(filterType: nil)
                }
            }

            ForEach(types, id: \.self) { type in
                verticalButton(
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
    }

    @ViewBuilder
    private var horizontalBar: some View {
        HStack(spacing: 25) {
            if viewModel.currentFilters.isNotEmpty {
                Menu {
                    Button(L10n.reset, role: .destructive) {
                        viewModel.reset(filterType: nil)
                    }
                } label: {
                    ZStack {
                        Text(String.space)
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                }
                .menuStyle(.button)
                .focused($focusTarget, equals: .reset)
                .foregroundStyle(.primary, .secondary)
                .accessibilityLabel(L10n.reset)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .controlSize(.small)
        .labelStyle(.trailingIcon)
        .buttonStyle(.capsule(selectionTint: accentColor))
    }

    var body: some View {
        ZStack {
            switch orientation {
            case .horizontal:
                horizontalBar
            case .vertical:
                verticalBar
            }
        }
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
