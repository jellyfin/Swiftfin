//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import SwiftUI

struct OrderedSectionSelectorView<Element: Displayable & Hashable>: View {

    @Environment(\.editMode)
    private var editMode

    @State
    private var focusedElement: Element?

    @StateObject
    private var selection: BindingBox<[Element]>

    private var disabledSelection: [Element] {
        sources.filter { !selection.value.contains($0) }
    }

    private var label: (Element) -> any View
    private let sources: [Element]
    private var systemImage: String

    private func move(from source: IndexSet, to destination: Int) {
        selection.value.move(fromOffsets: source, toOffset: destination)
        editMode?.wrappedValue = .inactive
    }

    private func select(element: Element) {
        if selection.value.contains(element) {
            selection.value.removeAll(where: { $0 == element })
        } else {
            selection.value.append(element)
        }
    }

    var body: some View {
        NavigationStack {
            SplitFormWindowView()
                .descriptionView {
                    Image(systemName: systemImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 400)
                }
                .contentView {
                    List {
                        EnabledSection(
                            elements: $selection.value,
                            label: label,
                            isEditing: editMode?.wrappedValue.isEditing ?? false,
                            select: select,
                            move: move,
                            header: {
                                Group {
                                    HStack {
                                        Text(L10n.enabled)
                                        Spacer()
                                        if editMode?.wrappedValue.isEditing ?? false {
                                            Button(L10n.done) {
                                                withAnimation {
                                                    editMode?.wrappedValue = .inactive
                                                }
                                            }
                                        } else {
                                            Button(L10n.edit) {
                                                withAnimation {
                                                    editMode?.wrappedValue = .active
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        )

                        DisabledSection(
                            elements: disabledSelection,
                            label: label,
                            isEditing: editMode?.wrappedValue.isEditing ?? false,
                            select: select
                        )
                    }
                    .environment(\.editMode, editMode)
                }
                .animation(.linear(duration: 0.2), value: selection.value)
        }
    }
}

private struct EnabledSection<Element: Displayable & Hashable>: View {

    @Binding
    var elements: [Element]

    let label: (Element) -> any View
    let isEditing: Bool
    let select: (Element) -> Void
    let move: (IndexSet, Int) -> Void
    let header: () -> any View

    var body: some View {
        Section {
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
                            .eraseToAnyView()

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
        } header: {
            header()
                .eraseToAnyView()
        }
    }
}

private struct DisabledSection<Element: Displayable & Hashable>: View {

    let elements: [Element]
    let label: (Element) -> any View
    let isEditing: Bool
    let select: (Element) -> Void

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
                            .eraseToAnyView()

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

    init(selection: Binding<[Element]>, sources: [Element]) {
        self._selection = StateObject(wrappedValue: BindingBox(source: selection))
        self.sources = sources
        self.label = { Text($0.displayTitle).foregroundColor(.primary).eraseToAnyView() }
        self.systemImage = "filemenu.and.selection"
    }

    func label(@ViewBuilder _ content: @escaping (Element) -> any View) -> Self {
        copy(modifying: \.label, with: content)
    }

    func systemImage(_ systemName: String) -> Self {
        copy(modifying: \.systemImage, with: systemName)
    }
}
