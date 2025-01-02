//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct OrderedSectionSelectorView<Element: Displayable & Hashable>: View {

    @Environment(\.editMode)
    private var editMode

    @StateObject
    private var selection: BindingBox<[Element]>

    private var disabledSelection: [Element] {
        sources.subtracting(selection.value)
    }

    private var label: (Element) -> any View
    private let sources: [Element]

    private func move(from source: IndexSet, to destination: Int) {
        selection.value.move(fromOffsets: source, toOffset: destination)
    }

    private func select(element: Element) {

        UIDevice.impact(.light)

        if selection.value.contains(element) {
            selection.value.removeAll(where: { $0 == element })
        } else {
            selection.value.append(element)
        }
    }

    private var isReordering: Bool {
        editMode?.wrappedValue.isEditing ?? false
    }

    var body: some View {
        List {
            Section(L10n.enabled) {

                if selection.value.isEmpty {
                    L10n.none.text
                        .foregroundStyle(.secondary)
                }

                ForEach(selection.value, id: \.self) { element in
                    Button {
                        if !isReordering {
                            select(element: element)
                        }
                    } label: {
                        HStack {
                            label(element)
                                .eraseToAnyView()

                            Spacer()

                            if !isReordering {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                .onMove(perform: move)
            }

            Section(L10n.disabled) {

                if disabledSelection.isEmpty {
                    L10n.none.text
                        .foregroundStyle(.secondary)
                }

                ForEach(disabledSelection, id: \.self) { element in
                    Button {
                        if !isReordering {
                            select(element: element)
                        }
                    } label: {
                        HStack {
                            label(element)
                                .eraseToAnyView()

                            Spacer()

                            if !isReordering {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
        .animation(.linear(duration: 0.2), value: selection.value)
        .toolbar {
            EditButton()
        }
    }
}

extension OrderedSectionSelectorView {

    init(selection: Binding<[Element]>, sources: [Element]) {
        self._selection = StateObject(wrappedValue: BindingBox(source: selection))
        self.sources = sources
        self.label = { Text($0.displayTitle).foregroundColor(.primary) }
    }

    func label(@ViewBuilder _ content: @escaping (Element) -> any View) -> Self {
        copy(modifying: \.label, with: content)
    }
}
