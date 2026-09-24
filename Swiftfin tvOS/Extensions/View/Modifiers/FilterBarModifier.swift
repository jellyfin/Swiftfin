//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct FilterBarModifier: ViewModifier {

    @Default(.Customization.Library.letterPickerOrientation)
    private var letterPickerOrientation

    @FocusState
    private var focusedFilter: FilterTrack.FocusTarget?

    @ObservedObject
    var viewModel: FilterViewModel

    let types: [ItemFilterType]

    private var edge: HorizontalEdge {
        letterPickerOrientation == .trailing ? .leading : .trailing
    }

    @ViewBuilder
    private var filters: some View {
        VStack(spacing: 20) {
            ForEach(subviews: FilterTrack(
                viewModel: viewModel,
                types: types,
                focus: $focusedFilter,
                style: .compact,
                iconEdge: edge
            )) { button in
                Color.clear
                    .frame(width: 64, height: 64)
                    .overlay(alignment: edge == .leading ? .leading : .trailing) {
                        button
                    }
            }
        }
        .scrollIfLargerThanContainer()
        .frame(width: 64)
        .coordinatedFocusScope(
            $focusedFilter,
            values: types.map(FilterTrack.FocusTarget.filter) + (viewModel.hasActiveFilters ? [.reset] : [])
        )
    }

    func body(content: Content) -> some View {
        if types.isEmpty {
            content
        } else {
            content
                .focusSection()
                .safeAreaInset(edge: edge, alignment: .center, spacing: 0) {
                    filters
                        .coordinatedFocus(.secondary)
                        .padding(edge.asEdgeSet, EdgeInsets.itemSpacing)
                }
                .ignoresSafeArea(.all, edges: edge.asEdgeSet)
        }
    }
}
