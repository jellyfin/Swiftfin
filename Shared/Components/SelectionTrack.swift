//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SelectionTrack<Elements: RandomAccessCollection>: View where Elements.Element: Identifiable & Displayable {

    private let elements: Elements
    private let selection: Elements.Element.ID?
    private let focus: FocusState<Elements.Element.ID?>.Binding
    private let spacing: CGFloat
    private let action: (Elements.Element) -> Void

    init(
        _ elements: Elements,
        selection: Elements.Element.ID?,
        focus: FocusState<Elements.Element.ID?>.Binding,
        spacing: CGFloat = 20,
        action: @escaping (Elements.Element) -> Void
    ) {
        self.elements = elements
        self.selection = selection
        self.focus = focus
        self.spacing = spacing
        self.action = action
    }

    private var setID: Elements.Element.ID? {
        focus.wrappedValue ?? selection
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(elements) { element in
                Button(element.displayTitle) {
                    action(element)
                }
                .focused(focus, equals: element.id)
                .isSelected(setID == element.id)
            }
        }
        .buttonStyle(.capsule(isSelectionActive: focus.wrappedValue != nil))
    }
}
