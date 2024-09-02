//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Factory
import SwiftUI

struct OrderedSectionSelectorView<Element: Displayable & Hashable>: View {
    @Environment(\.editMode)
    private var editMode

    @Binding
    private var selection: [Element]

    @State
    private var updateSelection: [Element]

    @State
    private var focusedElement: Element?

    private var disabledSelection: [Element] {
        sources.filter { !updateSelection.contains($0) }
    }

    private var label: (Element) -> AnyView
    private let sources: [Element]
    private let image: Image
    private let title: String

    private func move(from source: IndexSet, to destination: Int) {
        updateSelection.move(fromOffsets: source, toOffset: destination)
        editMode?.wrappedValue = .inactive
    }

    private func select(element: Element) {
        if updateSelection.contains(element) {
            updateSelection.removeAll(where: { $0 == element })
        } else {
            updateSelection.append(element)
        }
    }

    var body: some View {
        NavigationView {
            SplitFormWindowView()
                .descriptionView {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 400)
                }
                .contentView {
                    List {
                        EnabledSection(
                            elements: $updateSelection,
                            label: label,
                            isEditing: editMode?.wrappedValue.isEditing ?? false,
                            select: select,
                            move: move,
                            focusedElement: $focusedElement
                        )

                        DisabledSection(
                            elements: disabledSelection,
                            label: label,
                            isEditing: editMode?.wrappedValue.isEditing ?? false,
                            select: select,
                            focusedElement: $focusedElement
                        )
                    }
                    .environment(\.editMode, editMode)
                }
                .withDescriptionTopPadding()
                .navigationTitle(title)
                .animation(.linear(duration: 0.2), value: updateSelection)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(editMode?.wrappedValue.isEditing ?? false ? "Done" : "Edit") {
                            withAnimation {
                                if editMode?.wrappedValue.isEditing ?? false {
                                    editMode?.wrappedValue = .inactive
                                } else {
                                    editMode?.wrappedValue = .active
                                }
                            }
                        }
                    }
                }
                .onChange(of: updateSelection) { _, newValue in
                    selection = newValue
                }
        }
    }
}

private struct EnabledSection<Element: Displayable & Hashable>: View {

    @Binding
    var elements: [Element]

    let label: (Element) -> AnyView
    let isEditing: Bool
    let select: (Element) -> Void
    let move: (IndexSet, Int) -> Void

    @Binding
    var focusedElement: Element?

    var body: some View {
        Section(L10n.enabled) {
            if elements.isEmpty {
                Text(L10n.none)
                    .foregroundStyle(.secondary)
            }

            ForEach(elements, id: \.self) { element in
                Button {
                    if !isEditing {
                        select(element)
                    }
                } label: {
                    HStack {
                        label(element)

                        Spacer()

                        if !isEditing {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .onMove(perform: move)
        }
    }
}

private struct DisabledSection<Element: Displayable & Hashable>: View {

    let elements: [Element]

    let label: (Element) -> AnyView
    let isEditing: Bool
    let select: (Element) -> Void

    @Binding
    var focusedElement: Element?

    var body: some View {
        Section(L10n.disabled) {
            if elements.isEmpty {
                Text(L10n.none)
                    .foregroundStyle(.secondary)
            }

            ForEach(elements, id: \.self) { element in
                Button {
                    if !isEditing {
                        select(element)
                    }
                } label: {
                    HStack {
                        label(element)

                        Spacer()

                        if !isEditing {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }
}

extension OrderedSectionSelectorView {

    init(title: String, selection: Binding<[Element]>, sources: [Element], image: Image = Image(systemName: "filemenu.and.selection")) {
        self.title = title
        self._selection = selection
        self._updateSelection = State(initialValue: selection.wrappedValue)
        self.sources = sources
        self.label = { Text($0.displayTitle).foregroundColor(.primary).eraseToAnyView() }
        self.image = image
    }

    func label(@ViewBuilder _ content: @escaping (Element) -> AnyView) -> Self {
        var copy = self
        copy.label = content
        return copy
    }
}
