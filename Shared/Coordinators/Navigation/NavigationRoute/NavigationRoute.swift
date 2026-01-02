//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

struct NavigationRoute: Identifiable, Hashable {

    enum TransitionStyle: Hashable {

        // TODO: sheet and fullscreen with `NavigationTransition`
        case push(NavigationTransition)
        case sheet
        case fullscreen
    }

    enum TransitionType {

        case automatic(TransitionStyle)
        case withNamespace((Namespace.ID) -> TransitionStyle)
    }

    let id: String

    private let content: AnyView
    var transitionType: TransitionType
    var namespace: Namespace.ID?

    var transitionStyle: TransitionStyle {
        switch transitionType {
        case let .automatic(style):
            return style
        case let .withNamespace(builder):
            if let namespace {
                return builder(namespace)
            } else {
                return .push(.automatic)
            }
        }
    }

    init(
        id: String,
        style: TransitionStyle = .push(.automatic),
        @ViewBuilder content: () -> some View
    ) {
        self.id = id
        self.transitionType = .automatic(style)
        self.namespace = nil
        self.content = AnyView(content())
    }

    init(
        id: String,
        withNamespace: @escaping (Namespace.ID) -> TransitionStyle,
        @ViewBuilder content: () -> some View
    ) {
        self.id = id
        self.transitionType = .withNamespace(withNamespace)
        self.namespace = nil
        self.content = AnyView(content())
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    @ViewBuilder
    var destination: some View {
        if case let .push(style) = transitionStyle {
            content
                .backport
                .navigationTransition(style)
        } else {
            content
        }
    }
}
