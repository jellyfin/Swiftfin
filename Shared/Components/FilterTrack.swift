//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FilterTrack: View {

    @AdaptiveLayout
    private var viewLayout

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

    @AppTheme
    private var theme

    @ObservedObject
    var viewModel: FilterViewModel

    @Router
    private var router

    let types: [ItemFilterType]
    let focus: FocusState<FocusTarget?>.Binding
    var style: Style = .regular
    var iconEdge: HorizontalEdge = .leading

    static func controlSize(for layout: ViewLayout) -> ControlSize {
        layout.value(standard: .small, large: .large)
    }

    static func metrics(for layout: ViewLayout) -> CapsuleButtonStyle.CapsuleControlMetrics {
        .init(controlSize(for: layout), layout: layout)
    }

    private var metrics: CapsuleButtonStyle.CapsuleControlMetrics {
        Self.metrics(for: viewLayout)
    }

    private var collapsedLabelWidth: CGFloat {
        metrics.minimumHeight - 2 * metrics.horizontalPadding
    }

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

    @ContentBuilder
    private func buttonIcon(for target: FocusTarget, isCollapsed: Bool) -> some View {
        Image(systemName: target.systemImage)
            #if os(tvOS)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .frame(width: isCollapsed ? collapsedLabelWidth : nil)
            #endif
    }

    @ContentBuilder
    private func buttonLabel(for target: FocusTarget) -> some View {
        let showsTitle = style == .regular || focus.wrappedValue == target

        HStack(spacing: viewLayout.value(standard: 4, large: metrics.labelSpacing)) {
            if iconEdge == .leading {
                buttonIcon(for: target, isCollapsed: !showsTitle)
            }

            Text(target.title)
                .isVisible(showsTitle)

            if iconEdge == .trailing {
                buttonIcon(for: target, isCollapsed: !showsTitle)
            }
        }
        .lineLimit(1)
        .fixedSize()
        .frame(
            width: showsTitle ? nil : viewLayout.value(standard: 32, large: collapsedLabelWidth),
            alignment: iconEdge == .leading ? .leading : .trailing
        )
    }

    @ContentBuilder
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

    @ContentBuilder
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

    @ContentBuilder
    var body: some View {
        ForEach(targets, id: \.self) { target in
            button(for: target)
                .fixedSize()
        }
        .font(metrics.font)
        .controlSize(Self.controlSize(for: viewLayout))
        .buttonStyle(.capsule(selectionTint: theme.accentColor, focusTint: viewLayout.value(standard: nil, large: .white)))
        #if os(tvOS)
        .animation(.snappy(duration: 0.2), value: focus.wrappedValue)
        #endif
    }
}
