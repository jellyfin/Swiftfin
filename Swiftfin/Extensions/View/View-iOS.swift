//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI
import SwiftUIIntrospect

extension View {

    func detectOrientation(_ orientation: Binding<UIDeviceOrientation>) -> some View {
        modifier(DetectOrientation(orientation: orientation))
    }

    func navigationBarOffset(_ scrollViewOffset: Binding<CGFloat>, start: CGFloat, end: CGFloat) -> some View {
        modifier(NavigationBarOffsetModifier(scrollViewOffset: scrollViewOffset, start: start, end: end))
    }

    func navigationBarDrawer(@ViewBuilder _ drawer: @escaping () -> some View) -> some View {
        modifier(NavigationBarDrawerModifier(drawer: drawer))
    }

    @ViewBuilder
    func navigationBarFilterDrawer(
        viewModel: FilterViewModel,
        types: [ItemFilterType],
        onSelect: @escaping (NavigationBarFilterDrawer.Parameters) -> Void
    ) -> some View {
        if types.isEmpty {
            self
        } else {
            navigationBarDrawer {
                NavigationBarFilterDrawer(
                    viewModel: viewModel,
                    types: types,
                    action: onSelect
                )
            }
        }
    }

    @ViewBuilder
    func navigationBarCloseButton(
        disabled: Bool = false,
        _ action: @escaping () -> Void
    ) -> some View {
        modifier(
            NavigationBarCloseButtonModifier(
                disabled: disabled,
                action: action
            )
        )
    }

    @ViewBuilder
    func navigationBarMenuButton(
        isLoading: Bool = false,
        isHidden: Bool = false,
        @ViewBuilder _ content: @escaping () -> some View
    ) -> some View {
        modifier(
            NavigationBarMenuButtonModifier(
                isLoading: isLoading,
                isHidden: isHidden,
                menuContent: content
            )
        )
    }

    @ViewBuilder
    func listRowCornerRadius(_ radius: CGFloat) -> some View {
        introspect(.listCell, on: .iOS(.v16), .iOS(.v17), .iOS(.v18)) { cell in
            cell.layer.cornerRadius = radius
        }
    }
}
