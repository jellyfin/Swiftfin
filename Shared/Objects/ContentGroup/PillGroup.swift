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

    private let action: (Router.Wrapper, Element) -> Void
    private let displayTitle: String
    private let elements: [Element]
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
                EmptyLabel(element.displayTitle)
            }
        }

        var body: some View {
            ContentGroupSection {
                ScrollView(.horizontal) {
                    HStack(spacing: PosterHStackMetrics.itemSpacing) {
                        ForEach(elements) { element in
                            Button {
                                action(router, element)
                            } label: {
                                label(for: element)
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .labelStyle(CapsuleLabelStyle())
                            }
                            .foregroundStyle(.primary, .secondary)
                            .buttonBorderShape(.capsule)
                            .buttonStyle(.card)
                        }
                    }
                    .edgePadding(.horizontal)
                }
                .scrollIndicators(.hidden)
                .backport
                .scrollClipDisabled()
            } header: {
                if displayTitle.isNotEmpty {
                    Text(displayTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .accessibility(addTraits: [.isHeader])
                        .edgePadding(.horizontal)
                }
            }
            .focusSection()
        }
    }
}
