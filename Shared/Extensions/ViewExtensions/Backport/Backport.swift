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
    func scrollClipDisabled(_ disabled: Bool = true) -> some View {
        if #available(iOS 17, *) {
            content.scrollClipDisabled(disabled)
        } else {
            content.introspect(.scrollView, on: .iOS(.v15), .tvOS(.v15)) { scrollView in
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

extension ButtonBorderShape {

    static let circleBackport: ButtonBorderShape = {
        if #available(iOS 17, *) {
            return ButtonBorderShape.circle
        } else {
            return ButtonBorderShape.roundedRectangle
        }
    }()
}

enum NavigationTransition: Hashable {
    case automatic
    case zoom(sourceID: String, namespace: Namespace.ID)
}
