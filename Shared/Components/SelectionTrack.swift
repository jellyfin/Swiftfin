//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SelectionTrack<Elements: RandomAccessCollection, ID: Hashable>: View {

    private let elements: Elements
    private let id: KeyPath<Elements.Element, ID>
    private let title: KeyPath<Elements.Element, String>
    private let selection: ID?
    private let focus: FocusState<ID?>.Binding
    private let spacing: CGFloat
    private let action: (Elements.Element) -> Void

    init(
        _ elements: Elements,
        id: KeyPath<Elements.Element, ID>,
        title: KeyPath<Elements.Element, String>,
        selection: ID?,
        focus: FocusState<ID?>.Binding,
        spacing: CGFloat = 20,
        action: @escaping (Elements.Element) -> Void
    ) {
        self.elements = elements
        self.id = id
        self.title = title
        self.selection = selection
        self.focus = focus
        self.spacing = spacing
        self.action = action
    }

    private var setID: ID? {
        focus.wrappedValue ?? selection
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(elements, id: id) { element in
                Button(element[keyPath: title]) {
                    action(element)
                }
                .focused(focus, equals: element[keyPath: id])
                .isSelected(setID == element[keyPath: id])
            }
        }
        .buttonStyle(.capsule(isSelectionActive: focus.wrappedValue != nil))
    }
}

extension SelectionTrack where Elements.Element: Identifiable & Displayable, ID == Elements.Element.ID {

    init(
        _ elements: Elements,
        selection: ID?,
        focus: FocusState<ID?>.Binding,
        spacing: CGFloat = 20,
        action: @escaping (Elements.Element) -> Void
    ) {
        self.init(
            elements,
            id: \.id,
            title: \.displayTitle,
            selection: selection,
            focus: focus,
            spacing: spacing,
            action: action
        )
    }
}
