//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct InsetFilterBarModifier: ViewModifier {

    @Default(.Customization.Library.letterPickerOrientation)
    private var letterPickerOrientation

    @ObservedObject
    var viewModel: FilterViewModel

    let types: [ItemFilterType]

    private var edge: HorizontalEdge {
        letterPickerOrientation == .trailing ? .leading : .trailing
    }

    func body(content: Content) -> some View {
        if types.isEmpty {
            content
        } else {
            content
                .focusSection()
                .environment(\.filterBarEdge, edge)
                .safeAreaInset(edge: edge, alignment: .center, spacing: 0) {
                    FilterBar(
                        viewModel: viewModel,
                        types: types,
                        orientation: .vertical,
                        edge: edge
                    )
                    .offset(x: edge == .leading ? -EdgeInsets.edgePadding / 1.5 : EdgeInsets.edgePadding / 1.5)
                    .padding(edge == .leading ? .trailing : .leading, -EdgeInsets.edgePadding / 2)
                }
        }
    }
}
