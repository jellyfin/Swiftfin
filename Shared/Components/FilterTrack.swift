//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct FilterTrack: View {

    enum Style {
        case compact
        case regular
    }

    enum FocusTarget: Hashable {
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

    @ObservedObject
    var viewModel: FilterViewModel

    @Router
    private var router

    let types: [ItemFilterType]
    let focus: FocusState<FocusTarget?>.Binding
    var style: Style = .regular
    var iconEdge: HorizontalEdge = .leading

    private var targets: [FocusTarget] {
        (viewModel.hasActiveFilters ? [.reset] : []) + types.map(FocusTarget.filter)
    }

    private func isSelected(_ target: FocusTarget) -> Bool {
        switch target {
        case .reset:
            true
        case let .filter(type):
            viewModel.isFilterSelected(type: type)
        }
    }

    private func reset() {
        #if os(tvOS)
        focus.wrappedValue = types.first.map(FocusTarget.filter)
        #endif
        viewModel.reset(filterType: nil)
    }

    @ViewBuilder
    private func buttonIcon(for target: FocusTarget) -> some View {
        Image(systemName: target.systemImage)
            #if os(tvOS)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .padding(.vertical, 8)
            #endif
    }

    @ViewBuilder
    private func buttonLabel(for target: FocusTarget) -> some View {
        let showsTitle = style == .regular || focus.wrappedValue == target

        HStack(spacing: UIDevice.isTV ? 12 : 4) {
            if iconEdge == .leading {
                buttonIcon(for: target)
            }

            Text(target.title)
                .isVisible(showsTitle)

            if iconEdge == .trailing {
                buttonIcon(for: target)
            }
        }
        .lineLimit(1)
        .fixedSize()
        .frame(width: showsTitle ? nil : 32, alignment: iconEdge == .leading ? .leading : .trailing)
    }

    @ViewBuilder
    private var resetButton: some View {
        #if os(iOS)
        Menu(FocusTarget.reset.title, systemImage: FocusTarget.reset.systemImage) {
            Button(L10n.reset, role: .destructive, action: reset)
        }
        .labelStyle(.iconOnly)
        #else
        Button(action: reset) {
            buttonLabel(for: .reset)
        }
        #endif
    }

    @ViewBuilder
    private func button(for target: FocusTarget) -> some View {
        Group {
            switch target {
            case .reset:
                resetButton
            case let .filter(type):
                Button {
                    router.route(to: .filter(type: type, viewModel: viewModel))
                } label: {
                    buttonLabel(for: target)
                }
            }
        }
        .focused(focus, equals: target)
        .isSelected(isSelected(target))
        .accessibilityLabel(target.title)
    }

    var body: some View {
        ForEach(targets, id: \.self) { target in
            button(for: target)
                .fixedSize()
        }
        .font(UIDevice.isTV ? .callout : .footnote)
        .controlSize(UIDevice.isTV ? .large : .small)
        .buttonStyle(.capsule(selectionTint: accentColor, focusTint: UIDevice.isTV ? .white : nil))
        #if os(tvOS)
        .animation(.snappy(duration: 0.2), value: focus.wrappedValue)
        #endif
    }
}
