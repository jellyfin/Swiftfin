//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct OrderedSectionSelectorView<Element: Displayable & Hashable>: View {

    @Environment(\.editMode)
    private var editMode

    @Binding
    private var selection: [Element]

    @State
    private var updateSelection: [Element]

    private var disabledSelection: [Element] {
        sources.subtracting(updateSelection)
    }

    private var label: (Element) -> any View
    private let sources: [Element]

    private func move(from source: IndexSet, to destination: Int) {
        updateSelection.move(fromOffsets: source, toOffset: destination)
    }

    private func select(element: Element) {
        if updateSelection.contains(element) {
            updateSelection.removeAll(where: { $0 == element })
        } else {
            updateSelection.append(element)
        }
    }

    var body: some View {
        List {
            Section(L10n.enabled) {

                if updateSelection.isEmpty {
                    L10n.none.text
                        .foregroundStyle(.secondary)
                }

                ForEach(updateSelection, id: \.self) { element in
                    Button {
                        if !(editMode?.wrappedValue.isEditing ?? true) {
                            select(element: element)
                        }
                    } label: {
                        HStack {
                            label(element)
                                .eraseToAnyView()

                            Spacer()

                            if !(editMode?.wrappedValue.isEditing ?? false) {
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
                        if !(editMode?.wrappedValue.isEditing ?? true) {
                            select(element: element)
                        }
                    } label: {
                        HStack {
                            label(element)
                                .eraseToAnyView()

                            Spacer()

                            if !(editMode?.wrappedValue.isEditing ?? false) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
        .animation(.linear(duration: 0.2), value: updateSelection)
        .toolbar {
            EditButton()
        }
        .onChange(of: updateSelection) { newValue in
            selection = newValue
        }
    }
}

extension OrderedSectionSelectorView {

    init(selection: Binding<[Element]>, sources: [Element]) {
        self._selection = selection
        self._updateSelection = State(initialValue: selection.wrappedValue)
        self.sources = sources
        self.label = { Text($0.displayTitle).foregroundColor(.primary) }
    }

    func label(@ViewBuilder _ content: @escaping (Element) -> any View) -> Self {
        copy(modifying: \.label, with: content)
    }
}
