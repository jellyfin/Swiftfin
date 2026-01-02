//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

enum SelectorType {
    case single
    case multi
}

struct SelectorView<Element: Displayable & Hashable, Label: View>: View {

    @Default(.accentColor)
    private var accentColor

    @State
    private var selectedItems: Set<Element>

    private let selectionBinding: Binding<Set<Element>>
    private let sources: [Element]
    private var label: (Element) -> Label
    private let type: SelectorType

    private init(
        selection: Binding<Set<Element>>,
        sources: [Element],
        label: @escaping (Element) -> Label,
        type: SelectorType
    ) {
        self.selectionBinding = selection
        self._selectedItems = State(initialValue: selection.wrappedValue)
        self.sources = sources
        self.label = label
        self.type = type
    }

    private func handleSingleSelect(with element: Element) {
        selectedItems = [element]
        selectionBinding.wrappedValue = selectedItems
    }

    private func handleMultiSelect(with element: Element) {
        if selectedItems.contains(element) {
            selectedItems.remove(element)
        } else {
            selectedItems.insert(element)
        }
        selectionBinding.wrappedValue = selectedItems
    }

    var body: some View {
        List(sources, id: \.hashValue) { element in
            Button {
                switch type {
                case .single:
                    handleSingleSelect(with: element)
                case .multi:
                    handleMultiSelect(with: element)
                }
            } label: {
                HStack {
                    label(element)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if selectedItems.contains(element) {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .fontWeight(.bold)
                            .aspectRatio(1, contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(accentColor.overlayColor, accentColor)
                    }
                }
            }
        }
        .backport
        .onChange(of: selectionBinding.wrappedValue) { _, newValue in
            selectedItems = newValue
        }
    }
}

extension SelectorView where Label == Text {

    init(selection: Binding<[Element]>, sources: [Element], type: SelectorType) {
        let setBinding = Binding<Set<Element>>(
            get: { Set(selection.wrappedValue) },
            set: { newValue in
                selection.wrappedValue = Array(newValue)
            }
        )

        self.init(
            selection: setBinding,
            sources: sources,
            label: { Text($0.displayTitle).foregroundColor(.primary) },
            type: type
        )
    }

    init(selection: Binding<Element>, sources: [Element]) {
        let setBinding = Binding<Set<Element>>(
            get: { Set([selection.wrappedValue]) },
            set: { newValue in
                if let first = newValue.first {
                    selection.wrappedValue = first
                }
            }
        )

        self.init(
            selection: setBinding,
            sources: sources,
            label: { Text($0.displayTitle).foregroundColor(.primary) },
            type: .single
        )
    }
}

extension SelectorView {

    func label(@ViewBuilder _ content: @escaping (Element) -> Label) -> Self {
        copy(modifying: \.label, with: content)
    }
}
