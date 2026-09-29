//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

private struct FilterTrackLabelStyle: LabelStyle {

    @Environment(\.isFocused)
    private var isFocused

    let showsTitle: Bool
    let iconEdge: HorizontalEdge

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: UIDevice.isTV ? 12 : 4) {
            if iconEdge == .leading {
                configuration.icon
            }

            configuration.title
                .isVisible(showsTitle || isFocused)

            if iconEdge == .trailing {
                configuration.icon
            }
        }
        .lineLimit(1)
        .fixedSize()
        .frame(width: showsTitle || isFocused ? nil : 32, alignment: iconEdge == .leading ? .leading : .trailing)
    }
}

struct FilterTrack: View {

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
        Label {
            Text(target.title)
        } icon: {
            buttonIcon(for: target)
        }
    }

    @ViewBuilder
    private var menuActions: some View {
        if viewModel.selectedSavedFilter != nil {
            Button(L10n.edit, systemImage: "pencil") {
                router.route(to: .savedFilterEditor(viewModel: viewModel))
            }
        } else if viewModel.hasSavableFilters {
            Button(L10n.save, systemImage: "square.and.arrow.down") {
                router.route(to: .savedFilterEditor(viewModel: viewModel))
            }
        }

        Button(L10n.clear, systemImage: "text.badge.xmark", role: .destructive, action: reset)
    }

    @ViewBuilder
    private func button(for target: FocusTarget) -> some View {
        Group {
            switch target {
            case .options:
                Menu {
                    if viewModel.hasActiveFilters {
                        #if os(iOS)
                        if viewModel.savedFilters.isEmpty {
                            Section {
                                menuActions
                            }
                        } else {
                            ControlGroup {
                                menuActions
                            }
                        }
                        #else
                        Section {
                            menuActions
                        }
                        #endif
                    }

                    Section {
                        Picker(L10n.filters, selection: $viewModel.selectedSavedFilter) {
                            ForEach(viewModel.savedFilters) { savedFilter in
                                Text(savedFilter.name)
                                    .tag(savedFilter as SavedItemFilter?)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                } label: {
                    buttonLabel(for: target)
                }
                .menuStyle(.button)
                #if os(tvOS)
                .buttonStyle(
                    .capsule(
                        selectionTint: accentColor,
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
