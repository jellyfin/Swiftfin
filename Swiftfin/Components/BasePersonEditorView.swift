//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct BasePersonEditorView: View {
    let title: String

    @Binding
    var items: [BaseItemPerson]

    @State
    private var newPersonName: String = ""
    @State
    private var newPersonType: PersonKind = .unknown
    @State
    private var newPersonRole: String = ""

    var body: some View {
        List {
            ForEach(items.indices, id: \.self) { index in
                PersonRowView(person: $items[index])
                    .swipeActions {
                        Button(role: .destructive) {
                            deleteItem(at: index)
                        } label: {
                            Label(L10n.delete, systemImage: "trash")
                        }
                    }
            }
            .onMove(perform: moveItems)

            NewPersonInputView(
                newPersonName: $newPersonName,
                newPersonType: $newPersonType,
                newPersonRole: $newPersonRole,
                addAction: addItem
            )
        }
        .environment(\.editMode, .constant(.active))
    }

    // MARK: - Add a New Person

    private func addItem() {
        guard !newPersonName.isEmpty else { return }
        let newPerson = BaseItemPerson(
            name: newPersonName,
            role: newPersonType == .actor ? newPersonRole : nil,
            type: newPersonType.rawValue
        )
        items.append(newPerson)
        newPersonName = ""
        newPersonType = .actor
        newPersonRole = ""
    }

    // MARK: - Delete a Person

    private func deleteItem(at index: Int) {
        items.remove(at: index)
    }

    // MARK: - Move a Person

    private func moveItems(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
}

// MARK: - Person Row View

extension BasePersonEditorView {
    private struct PersonRowView: View {
        @Binding
        var person: BaseItemPerson

        var body: some View {
            HStack {
                VStack(alignment: .leading) {
                    TextField(L10n.name, text: Binding(
                        get: { person.name ?? "" },
                        set: { person.name = $0 }
                    ))
                    .font(.headline)

                    Picker(L10n.type, selection: Binding(
                        get: { PersonKind(type: person.type) },
                        set: { person.type = $0.rawValue }
                    )) {
                        ForEach(PersonKind.allCases, id: \.self) { type in
                            Text(type.displayTitle).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .foregroundStyle(.primary, .secondary)

                    if person.type == PersonKind.actor.rawValue {
                        TextField(L10n.role, text: Binding(
                            get: { person.role ?? "" },
                            set: { person.role = $0 }
                        ))
                        .foregroundColor(.secondary)
                    }
                }
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - New Person Row View

extension BasePersonEditorView {
    private struct NewPersonInputView: View {
        @Binding
        var newPersonName: String
        @Binding
        var newPersonType: PersonKind
        @Binding
        var newPersonRole: String

        var addAction: () -> Void

        var body: some View {
            HStack {
                VStack {
                    TextField("New person", text: $newPersonName)
                        .font(.headline)
                        .onSubmit { addAction() }

                    Picker("Type", selection: $newPersonType) {
                        ForEach(PersonKind.allCases, id: \.self) { type in
                            Text(type.displayTitle).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .foregroundStyle(.primary, .secondary)

                    if newPersonType == .actor {
                        TextField(L10n.role, text: $newPersonRole)
                            .onSubmit { addAction() }
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                Button(action: addAction) {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(newPersonName.isEmpty)
            }
        }
    }
}
