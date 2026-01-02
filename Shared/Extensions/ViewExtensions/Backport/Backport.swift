//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct Backport<Content> {

    let content: Content
}

extension Backport where Content: View {

    @ViewBuilder
    func buttonBorderShape(_ shape: ButtonBorderShape) -> some View {
        content.buttonBorderShape(shape.swiftUIValue)
    }

    @ViewBuilder
    func toolbarTitleDisplayMode(_ mode: ToolbarTitleDisplayMode) -> some View {
        if #available(iOS 17, tvOS 17, *) {
            content.toolbarTitleDisplayMode(mode.swiftUIValue)
        } else {
            content.navigationBarTitleDisplayMode(mode.navigationBarTitleDisplayMode)
        }
    }

    @ViewBuilder
    func matchedTransitionSource(id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, tvOS 18.0, *) {
            content.matchedTransitionSource(
                id: id,
                in: namespace
            )
        } else {
            content
        }
    }

    @ViewBuilder
    func navigationTransition(_ style: NavigationTransition) -> some View {
        if #available(iOS 18.0, tvOS 18.0, *), case let .zoom(sourceID, namespace) = style {
            content.navigationTransition(
                .zoom(sourceID: sourceID, in: namespace)
            )
        } else {
            content
        }
    }

    @ViewBuilder
    func onChange<V: Equatable>(
        of value: V,
        _ action: @escaping (_ oldValue: V, _ newValue: V) -> Void
    ) -> some View {
        if #available(iOS 17, tvOS 17, *) {
            content.onChange(of: value, action)
        } else {
            content.onChange(of: value) { [value] newValue in
                action(value, newValue)
            }
        }
    }

    @MainActor
    @ViewBuilder
    func scrollClipDisabled(_ disabled: Bool = true) -> some View {
        if #available(iOS 17, *) {
            content.scrollClipDisabled(disabled)
        } else {
            content.introspect(.scrollView, on: .iOS(.v16), .tvOS(.v16)) { scrollView in
                scrollView.clipsToBounds = !disabled
            }
        }
    }

    /// - Important: This does nothing on tvOS.
    @ViewBuilder
    func searchFocused(
        _ isSearchFocused: FocusState<Bool>.Binding
    ) -> some View {
        #if os(iOS)
        if #available(iOS 18.0, *) {
            content.searchFocused(isSearchFocused)
        } else {
            content
        }
        #else
        content
        #endif
    }

    @available(iOS 9999, *)
    @ViewBuilder
    func tabViewStyle(_ style: TabViewStyle) -> some View {
        content.tabViewStyle(style.swiftUIValue)
            .eraseToAnyView()
    }
}
