//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension View {

    // TODO: remove after removing support for iOS 15

    @ViewBuilder
    func iOS15<Content: View>(@ViewBuilder _ content: (Self) -> Content) -> some View {
        if #available(iOS 16, *) {
            self
        } else {
            content(self)
        }
    }

    func detectOrientation(_ orientation: Binding<UIDeviceOrientation>) -> some View {
        modifier(DetectOrientation(orientation: orientation))
    }

    func navigationBarOffset(_ scrollViewOffset: Binding<CGFloat>, start: CGFloat, end: CGFloat) -> some View {
        modifier(NavigationBarOffsetModifier(scrollViewOffset: scrollViewOffset, start: start, end: end))
    }

    func navigationBarDrawer<Drawer: View>(@ViewBuilder _ drawer: @escaping () -> Drawer) -> some View {
        modifier(NavigationBarDrawerModifier(drawer: drawer))
    }

    @ViewBuilder
    func navigationBarFilterDrawer(
        viewModel: FilterViewModel,
        types: [ItemFilterType],
        onSelect: @escaping (FilterCoordinator.Parameters) -> Void
    ) -> some View {
        if types.isEmpty {
            self
        } else {
            navigationBarDrawer {
                NavigationBarFilterDrawer(
                    viewModel: viewModel,
                    types: types
                )
                .onSelect(onSelect)
            }
        }
    }

    func onAppDidEnterBackground(_ action: @escaping () -> Void) -> some View {
        onNotification(UIApplication.didEnterBackgroundNotification, perform: { _ in action() })
    }

    func onAppWillResignActive(_ action: @escaping () -> Void) -> some View {
        onNotification(UIApplication.willResignActiveNotification, perform: { _ in action() })
    }

    func onAppWillTerminate(_ action: @escaping () -> Void) -> some View {
        onNotification(UIApplication.willTerminateNotification, perform: { _ in action() })
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
}
