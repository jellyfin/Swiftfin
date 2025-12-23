//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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

    @available(tvOS, unavailable)
    @ViewBuilder
    func searchFocused(
        _ isSearchFocused: FocusState<Bool>.Binding
    ) -> some View {
        if #available(iOS 18.0, *) {
            content.searchFocused(isSearchFocused)
        } else {
            content
        }
    }

    // MARK: - tvOS Focus Animations

    /// Applies a scale effect based on focus state with platform-appropriate animation.
    /// On tvOS 18+, uses enhanced spring animation. On older versions, uses simpler easing.
    @ViewBuilder
    func focusedScaleEffect(focused: Bool) -> some View {
        #if os(tvOS)
        if #available(tvOS 18.0, *) {
            content
                .scaleEffect(focused ? 1.08 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: focused)
        } else {
            content
                .scaleEffect(focused ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: focused)
        }
        #else
        content
        #endif
    }

    /// Applies a shadow effect based on focus state for depth perception on tvOS.
    @ViewBuilder
    func focusedShadow(focused: Bool) -> some View {
        content
            .shadow(
                color: .black.opacity(focused ? 0.3 : 0.1),
                radius: focused ? 20 : 5,
                y: focused ? 10 : 2
            )
            .animation(.easeInOut(duration: 0.2), value: focused)
    }
}

// MARK: ButtonBorderShape

enum ButtonBorderShape {
    case automatic
    case capsule
    case roundedRectangle
    case circle

    var swiftUIValue: SwiftUI.ButtonBorderShape {
        switch self {
        case .automatic: .automatic
        case .capsule: .capsule
        case .roundedRectangle: .roundedRectangle
        case .circle:
            if #available(iOS 17, *) {
                .circle
            } else {
                .roundedRectangle
            }
        }
    }
}

enum NavigationTransition: Hashable {
    case automatic
    case zoom(sourceID: String, namespace: Namespace.ID)
}
