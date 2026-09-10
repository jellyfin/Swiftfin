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

    @ObservedObject
    var viewModel: FilterViewModel

    @Router
    private var router

    let types: [ItemFilterType]

    @ViewBuilder
    private var resetButton: some View {
        Menu(L10n.reset, systemImage: "line.3.horizontal.decrease") {
            Button(L10n.reset, role: .destructive) {
                viewModel.reset(filterType: nil)
            }
        }
        .foregroundStyle(.primary, .secondary)
        .labelStyle(NavigationDrawerLabelStyle(isIconOnly: true))
    }

    @ViewBuilder
    private func filterButton(for type: ItemFilterType) -> some View {
        Button(type.displayTitle, systemImage: "chevron.down") {
            router.route(
                to: .filter(
                    type: type,
                    viewModel: viewModel
                )
            )
        }
        .foregroundStyle(.primary, .secondary)
        .isHighlighted(viewModel.isFilterSelected(type: type))
    }

    #if os(macOS)
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    if viewModel.hasActiveFilters {
                        resetButton
                            .menuStyle(.button)
                            .menuIndicator(.hidden)
                            .buttonStyle(.plain)
                            .modifier(FilterCapsuleHoverModifier())
                    }

                    ForEach(types, id: \.self) { type in
                        filterButton(for: type)
                            .buttonStyle(.plain)
                            .modifier(FilterCapsuleHoverModifier())
                    }
                }
                .padding(.horizontal, EdgeInsets.edgePadding)
                .padding(.vertical, 5)
                .labelStyle(NavigationDrawerLabelStyle())
            }
            .scrollIndicators(.hidden)

            Divider()
        }
        .frame(maxWidth: .infinity)
        .background(.bar)
    }
    #else
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                if viewModel.hasActiveFilters {
                    resetButton
                }

                ForEach(types, id: \.self) { type in
                    filterButton(for: type)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 5)
            .labelStyle(NavigationDrawerLabelStyle())
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }
    #endif
}

#if os(macOS)

/// Pointer feedback for a filter capsule.
private struct FilterCapsuleHoverModifier: ViewModifier {

    @State
    private var isHovering: Bool = false

    func body(content: Content) -> some View {
        content
            .brightness(isHovering ? 0.08 : 0)
            .animation(.easeOut(duration: 0.12), value: isHovering)
            .onHover { isHovering = $0 }
    }
}
#endif
