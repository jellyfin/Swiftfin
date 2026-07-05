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

    func body(with viewModel: Empty) -> Body {
        Body(
            action: action,
            displayTitle: displayTitle,
            elements: elements
        )
    }

    struct Body: View {

        @Router
        private var router

        let action: (Router.Wrapper, Element) -> Void
        let displayTitle: String
        let elements: [Element]

        @ViewBuilder
        private func label(for element: Element) -> some View {
            if let imageable = element as? SystemImageable {
                Label(element.displayTitle, systemImage: imageable.systemImage)
            } else {
                Text(element.displayTitle)
            }
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                if displayTitle.isNotEmpty {
                    Text(displayTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .accessibility(addTraits: [.isHeader])
                        .edgePadding(.leading)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Array(elements.enumerated()), id: \.offset) { _, element in
                            Button {
                                action(router, element)
                            } label: {
                                label(for: element)
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary, .secondary)
                                    .padding(8)
                                    .background {
                                        Color.systemFill
                                            .cornerRadius(10)
                                    }
                            }
                            .foregroundStyle(.primary, .secondary)
                        }
                    }
                    .edgePadding(.horizontal)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}
