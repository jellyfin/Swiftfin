//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

/// Tracking `safeAreaBar` application necessary for `CollectionVGrid`
struct IsSafeAreaBarApplied: PreferenceKey {
    static var defaultValue: Bool = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

struct NavigationBarFilterDrawerModifier: ViewModifier {

    @Default(.isLiquidGlassEnabled)
    private var isLiquidGlassEnabled

    @ObservedObject
    var viewModel: FilterViewModel

    let types: [ItemFilterType]

    @ViewBuilder
    private var drawer: some View {
        NavigationBarFilterDrawer(
            viewModel: viewModel,
            types: types
        )
    }

    func body(content: Content) -> some View {
        if types.isEmpty {
            content
        } else {
            if #available(iOS 26, *), isLiquidGlassEnabled {
                content
                    .safeAreaBar(edge: .top, spacing: 0) {
                        drawer
                    }
                    .preference(key: IsSafeAreaBarApplied.self, value: true)
            } else {
                NavigationBarDrawerView {
                    drawer
                        .ignoresSafeArea()
                } content: {
                    content
                }
                .ignoresSafeArea()
            }
        }
    }
}
