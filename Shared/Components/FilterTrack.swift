//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

private struct FilterTrackLabelStyle: LabelStyle {

    @AdaptiveLayout
    private var viewLayout

    @Environment(\.isFocused)
    private var isFocused

    let showsTitle: Bool
    let iconEdge: HorizontalEdge

    private var metrics: CapsuleButtonStyle.CapsuleControlMetrics {
        FilterTrack.metrics(for: viewLayout)
    }

    private var collapsedLabelWidth: CGFloat {
        metrics.minimumHeight - 2 * metrics.horizontalPadding
    }

    @ContentBuilder
    private func icon(_ image: some View) -> some View {
        image
            #if os(tvOS)
                .frame(width: showsTitle || isFocused ? nil : collapsedLabelWidth)
            #endif
    }

    @ContentBuilder
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: viewLayout.value(standard: 4, large: metrics.labelSpacing)) {
            if iconEdge == .leading {
                icon(configuration.icon)
            }

            configuration.title
                .isVisible(showsTitle || isFocused)

            if iconEdge == .trailing {
                icon(configuration.icon)
            }
        }
        .lineLimit(1)
        .fixedSize()
        .frame(
            width: showsTitle || isFocused ? nil : viewLayout.value(standard: 32, large: collapsedLabelWidth),
            alignment: iconEdge == .leading ? .leading : .trailing
        )
    }
}

struct FilterTrack: View {

    @AdaptiveLayout
    private var viewLayout

    enum Style {

        case compact
        case regular
    }

    enum FocusTarget: Hashable {

        case options
        case filter(ItemFilterType)

        var title: String {
            switch self {
            case .options:
                L10n.options
            case let .filter(type):
                type.displayTitle
            }
        }

        var systemImage: String {
            switch self {
            case .options:
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

    private var targets: [FocusTarget] {
        (viewModel.hasFilterOptions ? [.options] : []) + types.map(FocusTarget.filter)
    }

    private func isSelected(_ target: FocusTarget) -> Bool {
        switch target {
        case .options:
            viewModel.hasActiveFilters
        case let .filter(type):
            viewModel.isFilterSelected(type: type)
        }
    }

    private func reset() {
        #if os(tvOS)
        if viewModel.savedFilters.isEmpty {
            focus.wrappedValue = types.first.map(FocusTarget.filter)
        }
        #endif

        viewModel.reset(filterType: nil)
    }

    @ContentBuilder
    private func buttonIcon(for target: FocusTarget) -> some View {
        Image(systemName: target.systemImage)
            #if os(tvOS)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
            #endif
    }

    @ContentBuilder
    private func buttonLabel(for target: FocusTarget) -> some View {
        Label {
            Text(target.title)
        } icon: {
            buttonIcon(for: target)
        }
    }

    @ContentBuilder
    private var menuActions: some View {
        Button(
            viewModel.selectedSavedFilter == nil ? L10n.save : L10n.edit,
            systemImage: viewModel.selectedSavedFilter == nil ? "square.and.arrow.down" : "pencil"
        ) {
            router.route(
                to: .editFilters(
                    filters: viewModel.savableFilters,
                    savedFilter: viewModel.selectedSavedFilter,
                    onSave: { viewModel.selectedSavedFilter = $0 }
                )
            )
        }

        Button(L10n.clear, systemImage: "text.badge.xmark", role: .destructive, action: reset)
            .disabled(!viewModel.hasActiveFilters)
    }

    @ContentBuilder
    private func button(for target: FocusTarget) -> some View {
        Group {
            switch target {
            case .options:
                Menu {
                    if viewModel.hasActiveFilters || viewModel.selectedSavedFilter != nil {
                        if UIDevice.isTV || viewModel.savedFilters.isEmpty {
                            Section {
                                menuActions
                            }
                        } else {
                            ControlGroup {
                                menuActions
                            }
                        }
                    }

                    if viewModel.savedFilters.isNotEmpty {
                        Section(L10n.filters) {
                            ForEach(viewModel.savedFilters) { savedFilter in
                                Button {
                                    viewModel.selectedSavedFilter = savedFilter
                                } label: {
                                    if viewModel.selectedSavedFilter?.id == savedFilter.id {
                                        Label(savedFilter.name, systemImage: "checkmark")
                                    } else {
                                        Text(savedFilter.name)
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    buttonLabel(for: target)
                }
                .menuStyle(.button)
                #if os(tvOS)
                .buttonStyle(
                    .capsule(
                        selectionTint: theme.accentColor,
                        focusTint: .white,
                        anchor: style == .compact ? iconEdge : nil
                    )
                )
                #else
                .labelStyle(.iconOnly)
                #endif

            case let .filter(type):
                Button {
                    router.route(to: .filter(type: type, viewModel: viewModel))
                } label: {
                    buttonLabel(for: target)
                }
            }
        }
        .labelStyle(
            FilterTrackLabelStyle(
                showsTitle: style == .regular || focus.wrappedValue == target,
                iconEdge: iconEdge
            )
        )
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
