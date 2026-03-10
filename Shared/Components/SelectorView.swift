//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

enum SelectorType {
    case single
    case multi
}

struct SelectorView<Element: Hashable, Label: View>: View {

    @StateObject
    private var box: BindingBox<Set<Element>>

    private let sources: [Element]
    private var label: (Element) -> Label
    private let type: SelectorType

    init(
        selection: Binding<[Element]>,
        sources: [Element],
        type: SelectorType,
        label: @escaping (Element) -> Label,
    ) {
        self._box = StateObject(
            wrappedValue: BindingBox(
                source: selection.map(
                    getter: { Set($0) },
                    setter: { Array($0) }
                )
            )
        )
        self.sources = sources
        self.label = label
        self.type = type
    }

    init(
        selection: Binding<Element>,
        sources: [Element],
        label: @escaping (Element) -> Label,
    ) {
        self._box = StateObject(
            wrappedValue: BindingBox(
                source: selection.map(
                    getter: { Set([$0]) },
                    setter: { $0.first! }
                )
            )
        )
        self.sources = sources
        self.label = label
        self.type = .single
    }

    var body: some View {
        List(sources, id: \.hashValue) { element in
            Button {
                switch type {
                case .single:
                    box.value = [element]
                case .multi:
                    box.value.toggle(value: element)
                }
            } label: {
                HStack {
                    label(element)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    let isSelected = box.value.contains(element)

                    if isSelected {
                        ListRowCheckbox()
                            .isEditing(true)
                            .isSelected(isSelected)
                    }
                }
            }
            .foregroundStyle(.primary, .secondary)
        }
    }
}

extension SelectorView where Element: Displayable, Label == Text {

    init(selection: Binding<[Element]>, sources: [Element], type: SelectorType) {
        self.init(
            selection: selection,
            sources: sources,
            type: type,
            label: { Text($0.displayTitle) }
        )
    }

    init(selection: Binding<Element>, sources: [Element]) {
        self.init(
            selection: selection,
            sources: sources,
            label: { Text($0.displayTitle) }
        )
    }
}

extension SelectorView {

    @available(*, deprecated, message: "Use SelectorView(selection:sources:type:label:) instead")
    func label(@ViewBuilder _ content: @escaping (Element) -> Label) -> Self {
        copy(modifying: \.label, with: content)
    }
}
