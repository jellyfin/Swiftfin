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

    enum TransitionStyle: Hashable {

        case push(NavigationTransition)
        case sheet
        case fullscreen
    }

    let id: String

    private let content: AnyView
    var transitionStyle: TransitionStyle

    init(
        id: String,
        style: TransitionStyle = .push(.automatic),
        @ViewBuilder content: () -> some View
    ) {
        self.id = id
        self.transitionStyle = style
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
        if case let .push(style) = transitionStyle {
            content
                .backport
                .navigationTransition(style)
        } else {
            content
        }
    }
}
