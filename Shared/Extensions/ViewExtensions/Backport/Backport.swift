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
