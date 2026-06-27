//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import SwiftUI

// TODO: trailing content refactor?

struct PosterHStack<Element: Poster, Data: Collection>: View where Data.Element == Element, Data.Index == Int {

    private var data: Data
    private var title: String?
    private var type: PosterDisplayType
    private var label: (Element) -> any View
    private var trailingContent: () -> any View
    private let action: (Element) -> Void
    // When set, EVERY poster carries this focus binding keyed by `AnyHashable(item.id)`, so callers
    // can both observe which item is focused and RESTORE focus to an arbitrary item (e.g. the
    // last-focused cast member) by setting the bound value.
    private var focusedItem: FocusState<AnyHashable?>.Binding?
    private var titleFont: Font = .system(size: 32, weight: .semibold)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            if let title {
                HStack {
                    Text(title)
                        .font(titleFont)
                        // Same legibility treatment as the poster labels, so section headers stay
                        // readable when a bright/white spotlight bleeds through the frosted home
                        // sections. No-op over dark backgrounds elsewhere.
                        .posterLabelShadow()
                        .accessibility(addTraits: [.isHeader])
                        .padding(.leading, 50)

                    Spacer()
                }
            }

            CollectionHStack(
                uniqueElements: data,
                columns: type == .landscape ? 4 : 7
            ) { item in
                posterButton(for: item)
            }
            .clipsToBounds(false)
            .dataPrefix(20)
            .insets(horizontal: EdgeInsets.edgePadding, vertical: 10)
            .itemSpacing(EdgeInsets.edgePadding - 20)
            .scrollBehavior(.continuousLeadingEdge)
        }
        .focusSection()
    }

    @ViewBuilder
    private func posterButton(for item: Element) -> some View {
        let button = PosterButton(
            item: item,
            type: type
        ) {
            action(item)
        } label: {
            label(item).eraseToAnyView()
        }

        // Per-item focus binding (keyed by id) lets the caller track and restore focus to any specific
        // poster (used by the cast/first-row "remember the last-focused card" logic).
        if let focusedItem {
            button.focused(focusedItem, equals: AnyHashable(item.id))
        } else {
            button
        }
    }
}

extension PosterHStack {

    init(
        title: String? = nil,
        type: PosterDisplayType,
        items: Data,
        focusedItem: FocusState<AnyHashable?>.Binding? = nil,
        titleFont: Font = .system(size: 32, weight: .semibold),
        action: @escaping (Element) -> Void,
        @ViewBuilder label: @escaping (Element) -> any View = { PosterButton<Element>.TitleSubtitleContentView(item: $0) }
    ) {
        self.init(
            data: items,
            title: title,
            type: type,
            label: label,
            trailingContent: { EmptyView() },
            action: action,
            focusedItem: focusedItem,
            titleFont: titleFont
        )
    }

    func trailing(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.trailingContent, with: content)
    }
}
