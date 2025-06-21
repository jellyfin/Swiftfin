//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

struct NavigationRoute: Identifiable, Hashable {

    enum Transition: Hashable {

        case push(Push)
        case sheet
        case fullscreen

        enum Push: Hashable {
            case automatic
            case zoom
        }
    }

    let id: String

    private let content: AnyView
    var transition: Transition

    init(
        id: String,
        routeType: Transition = .push(.automatic),
        @ViewBuilder content: () -> some View
    ) {
        self.id = id
        self.transition = routeType
        self.content = AnyView(content())
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    @ViewBuilder
    func destination(in namespace: Namespace.ID?) -> some View {
        if case let .push(transition) = transition {
            content
                .withNavigationTransition(
                    transition,
                    id: id,
                    in: namespace
                )
        } else {
            content
        }
    }
}

extension View {

    @ViewBuilder
    func withNavigationTransition(
        _ transition: NavigationRoute.Transition.Push,
        id: String,
        in namespace: Namespace.ID?
    ) -> some View {
        switch transition {
        case .automatic:
            self
        case .zoom:
            self.withZoomIfAvailable(id: id, in: namespace)
        }
    }

    @ViewBuilder
    func withZoomIfAvailable(id: String, in namespace: Namespace.ID?) -> some View {
        if #available(iOS 18, tvOS 18, *), let namespace {
            self.navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }
}
