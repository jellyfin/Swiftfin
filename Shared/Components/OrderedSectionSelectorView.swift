//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct OrderedSectionSelectorView<Element: Displayable & Hashable>: View {

    #if os(iOS)
    @Environment(\.editMode)
    private var editMode
    #else
    @State
    private var isMacEditing = false
    #endif

    @StateObject
    private var selection: PublishedBox<[Element]>

    private let data: [Element]
    private let removable: [Element]
    private let systemImage: String

    init(
        systemImage: String = "filemenu.and.selection",
        selection: Binding<[Element]>,
        sources: [Element],
        removable: [Element]? = nil
    ) {
        self._selection = StateObject(wrappedValue: PublishedBox(source: selection))
        self.data = sources
        self.removable = removable ?? sources
        self.systemImage = systemImage
    }

    private func isRemovable(_ element: Element) -> Bool {
        removable.contains(element)
    }

    private var disabledSelection: [Element] {
        data.subtracting(selection.value).filter(isRemovable)
    }

    private var isReordering: Bool {
        #if os(iOS)
        editMode?.wrappedValue.isEditing == true
        #else
        isMacEditing
        #endif
    }

    private func select(element: Element) {
        guard isRemovable(element) else { return }
        selection.value.toggle(element)
        UIDevice.impact(.light)
    }

    @ViewBuilder
    private var editButton: some View {
        Button(isReordering ? L10n.done : L10n.edit) {
            #if os(iOS)
            editMode?.wrappedValue = isReordering ? .inactive : .active
            #else
            isMacEditing.toggle()
            #endif
        }
        #if os(iOS)
        .backport
        .buttonStyle(.glass)
        .controlSize(.small)
        #endif
    }

    @ViewBuilder
    private func button(
        for element: Element,
        @ViewBuilder content: () -> some View
    ) -> some View {
        Button {
            select(element: element)
        } label: {
            LabeledContent(content: content) {
                if let imageable = element as? SystemImageable {
                    Label(element.displayTitle, systemImage: imageable.systemImage)
                        .symbolRenderingMode(.monochrome)
                } else {
                    Text(element.displayTitle)
                }
            }
        }
        .disabled(isReordering)
        .foregroundStyle(.primary, .secondary)
    }

    var body: some View {
        SwiftfinForm(systemImage: systemImage) {
            Section(L10n.enabled) {
                if selection.value.isEmpty {
                    Text(L10n.none)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(selection.value, id: \.self) { element in
                        button(for: element) {
                            if !isReordering, isRemovable(element) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .onMove {
                        selection.value.move(fromOffsets: $0, toOffset: $1)
                    }
                }
            }

            Section(L10n.disabled) {
                if disabledSelection.isEmpty {
                    Text(L10n.none)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(disabledSelection, id: \.self) { element in
                        button(for: element) {
                            if !isReordering {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
        }
        .animation(.linear(duration: 0.2), value: selection.value)
        #if os(iOS)
            .animation(.linear(duration: 0.2), value: editMode?.wrappedValue)
        #else
            .animation(.linear(duration: 0.2), value: isMacEditing)
        #endif
            .toolbar {
                editButton
            }
    }
}
