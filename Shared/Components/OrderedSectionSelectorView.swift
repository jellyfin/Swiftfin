//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct OrderedSectionSelectorView<Element: Displayable & Hashable>: View {

    @Environment(\.editMode)
    private var editMode

    @StateObject
    private var selection: BindingBox<[Element]>

    private var label: (Element) -> any View
    private let sources: [Element]
    private var systemImage: String

    private var disabledSelection: [Element] {
        sources.subtracting(selection.value)
    }

    private var isReordering: Bool {
        editMode?.wrappedValue.isEditing == true
    }

    private var editButton: some View {
        Button(isReordering ? L10n.done : L10n.edit) {
            withAnimation {
                editMode?.wrappedValue = isReordering ? .inactive : .active
            }
        }
    }

    // MARK: - Actions

    private func move(from source: IndexSet, to destination: Int) {
        selection.value.move(fromOffsets: source, toOffset: destination)
        UIDevice.impact(.light)
    }

    private func select(element: Element) {
        if selection.value.contains(element) {
            selection.value.removeAll(where: { $0 == element })
        } else {
            selection.value.append(element)
        }
        UIDevice.impact(.light)
    }

    // MARK: - Body

    var body: some View {
        Form(systemImage: systemImage) {
            Section(L10n.enabled) {
                if selection.value.isEmpty {
                    Text(L10n.none)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(selection.value, id: \.self) { element in
                        Button {
                            select(element: element)
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
                        .disabled(isReordering)
                    }
                    .onMove(perform: move)
                }
            }

            Section(L10n.disabled) {
                if disabledSelection.isEmpty {
                    Text(L10n.none)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(disabledSelection, id: \.self) { element in
                        Button {
                            select(element: element)
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
                        .disabled(isReordering)
                    }
                }
            }
        }
        .animation(.linear(duration: 0.2), value: selection.value)
        .toolbar {
            editButton
        }
    }
}

extension OrderedSectionSelectorView {

    init(_ systemImage: String = "filemenu.and.selection", selection: Binding<[Element]>, sources: [Element]) {
        self._selection = StateObject(wrappedValue: BindingBox(source: selection))

        self.sources = sources
        self.systemImage = "filemenu.and.selection"

        self.label = {
            Text($0.displayTitle).foregroundColor(.primary).eraseToAnyView()
        }
    }

    func label(@ViewBuilder _ content: @escaping (Element) -> any View) -> Self {
        copy(modifying: \.label, with: content)
    }
}
