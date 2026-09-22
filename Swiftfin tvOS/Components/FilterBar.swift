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

        var title: String {
            switch self {
            case .reset:
                L10n.reset
            case let .filter(type):
                type.displayTitle
            }
        }

        var systemImage: String {
            switch self {
            case .reset:
                "line.3.horizontal.decrease"
            case let .filter(type):
                type.systemImage
            }
        }
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

    private var targets: [FocusTarget] {
        (viewModel.currentFilters.isNotEmpty ? [.reset] : []) + types.map(FocusTarget.filter)
    }

    private var preferredFocusTarget: FocusTarget? {
        lastFocusTarget.flatMap { targets.contains($0) ? $0 : nil } ?? types.first.map(FocusTarget.filter)
    }

    private func isSelected(_ target: FocusTarget) -> Bool {
        switch target {
        case .reset:
            false
        case let .filter(type):
            viewModel.isFilterSelected(type: type)
        }
    }

    private func action(_ target: FocusTarget) {
        switch target {
        case .reset:
            viewModel.reset(filterType: nil)
        case let .filter(type):
            router.route(to: .filter(type: type, viewModel: viewModel))
        }
    }

    @ViewBuilder
    private func buttonLabel(for target: FocusTarget) -> some View {
        switch orientation {
        case .horizontal:
            if target == .reset {
                Label(target.title, systemImage: target.systemImage)
                    .labelStyle(.iconOnly)
            } else {
                Label(target.title, systemImage: "chevron.down")
                    .labelStyle(.trailingIcon)
            }
        case .vertical:
            HStack(spacing: 12) {
                if focusTarget == target, edge == .trailing {
                    Text(target.title)
                        .transition(.opacity)
                }

                Image(systemName: target.systemImage)
                    .frame(width: buttonSize - 32, height: buttonSize - 16)

                if focusTarget == target, edge == .leading {
                    Text(target.title)
                        .transition(.opacity)
                }
            }
            .lineLimit(1)
        }
    }

    @ViewBuilder
    private func button(for target: FocusTarget) -> some View {
        Button {
            action(target)
        } label: {
            buttonLabel(for: target)
        }
        .focused($focusTarget, equals: target)
        .isSelected(isSelected(target))
        .foregroundStyle(.primary, .secondary)
        .accessibilityLabel(target.title)
    }

    var body: some View {
        Group {
            switch orientation {
            case .horizontal:
                HStack(spacing: 25) {
                    ForEach(targets, id: \.self, content: button)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .controlSize(.small)
            case .vertical:
                VStack(spacing: 20) {
                    ForEach(targets, id: \.self) { target in
                        Color.clear
                            .frame(width: buttonSize, height: buttonSize)
                            .overlay(alignment: edge == .leading ? .leading : .trailing) {
                                button(for: target)
                                    .fixedSize()
                            }
                            .zIndex(focusTarget == target ? 1 : 0)
                    }
                }
                .font(.callout)
                .controlSize(.large)
                .animation(.snappy(duration: 0.2), value: focusTarget)
                .scrollIfLargerThanContainer()
                .frame(width: buttonSize)
            }
        }
        .buttonStyle(.capsule(selectionTint: accentColor))
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
