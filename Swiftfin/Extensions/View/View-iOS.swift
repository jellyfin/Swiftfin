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
        onNotification(.applicationDidEnterBackground) {
            action()
        }
    }

    func onAppWillResignActive(_ action: @escaping () -> Void) -> some View {
        onNotification(.applicationWillResignActive) { _ in
            action()
        }
    }

    func onAppWillTerminate(_ action: @escaping () -> Void) -> some View {
        onNotification(.applicationWillTerminate) { _ in
            action()
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
    func navigationBarMenuButton<Content: View>(
        isLoading: Bool = false,
        isHidden: Bool = false,
        @ViewBuilder
        _ items: @escaping () -> Content
    ) -> some View {
        modifier(
            NavigationBarMenuButtonModifier(
                isLoading: isLoading,
                isHidden: isHidden,
                items: items
            )
        )
    }

    @ViewBuilder
    func listRowCornerRadius(_ radius: CGFloat) -> some View {
        if #unavailable(iOS 16) {
            introspect(.listCell, on: .iOS(.v15)) { cell in
                cell.layer.cornerRadius = radius
            }
        } else {
            introspect(
                .listCell,
                on: .iOS(.v16),
                .iOS(.v17),
                .iOS(.v18)
            ) { cell in
                cell.layer.cornerRadius = radius
            }
        }
    }
}
