//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct PillGroup<Element: Displayable>: ContentGroup {

    let action: (Router.Wrapper, Element) -> Void
    let displayTitle: String
    let elements: [Element]
    let id: String

    var _shouldBeResolved: Bool {
        elements.isNotEmpty
    }

    init(
        displayTitle: String,
        id: String,
        elements: [Element],
        action: @escaping (Router.Wrapper, Element) -> Void
    ) {
        self.action = action
        self.displayTitle = displayTitle
        self.id = id
        self.elements = elements
    }

    func body(with viewModel: Empty) -> some View {
        #if os(tvOS)
        EmptyView()
        #else
        WithRouter { router in
            PillHStack(
                title: displayTitle,
                data: elements
            ) { element in
                action(router, element)
            }
        }
        #endif
    }
}
