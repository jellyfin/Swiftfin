//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

struct PeopleEditorView: View {

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @State
    private var tempItem: BaseItemDto
    @State
    private var newPersonName: String = ""
    @State
    private var newPersonType: PersonKind = .unknown
    @State
    private var newPersonRole: String = ""
    @State
    private var isEditing: Bool = false

    @ObservedObject
    private var viewModel: UpdateMetadataViewModel

    init(item: BaseItemDto) {
        self.viewModel = UpdateMetadataViewModel(item: item)
        _tempItem = State(initialValue: item)
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(L10n.editWithItem(L10n.people))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? L10n.cancel : L10n.edit) {
                        if isEditing {
                            tempItem = viewModel.item
                            isEditing = false
                        } else {
                            isEditing = true
                        }
                    }
                    .buttonStyle(.toolbarPill)
                }
                ToolbarItem(placement: .bottomBar) {
                    if isEditing {
                        Button(L10n.save) {
                            viewModel.send(.update(tempItem))
                            isEditing = false
                        }
                        .buttonStyle(.toolbarPill)
                        .disabled(viewModel.item == tempItem)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .navigationBarCloseButton {
                router.dismissCoordinator()
            }
    }

    // MARK: - Content View

    private var contentView: some View {
        VStack {
            if isEditing || (tempItem.people?.isNotEmpty ?? false) {
                List {
                    ForEach(tempItem.people?.indices ?? [].indices, id: \.self) { index in
                        PersonRowView(person: Binding(
                            get: { tempItem.people?[index] ?? BaseItemPerson() },
                            set: { tempItem.people?[index] = $0 }
                        ))
                        .swipeActions {
                            Button(role: .destructive) {
                                deleteItem(at: index)
                            } label: {
                                Label(L10n.delete, systemImage: "trash")
                            }
                        }
                    }
                    if isEditing {
                        NewPersonInputView(
                            newPersonName: $newPersonName,
                            newPersonType: $newPersonType,
                            newPersonRole: $newPersonRole,
                            addAction: addItem
                        )
                    }
                }
                .disabled(!isEditing)
            } else {
                Text(L10n.none)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.zero)
            }
        }
    }

    // MARK: - Add a New Person

    private func addItem() {
        guard !newPersonName.isEmpty else { return }
        let newPerson = BaseItemPerson(
            name: newPersonName,
            role: newPersonType == .actor ? newPersonRole : nil,
            type: newPersonType.rawValue
        )
        if tempItem.people == nil {
            tempItem.people = []
        }
        tempItem.people?.append(newPerson)
        newPersonName = ""
        newPersonType = .actor
        newPersonRole = ""
    }

    // MARK: - Delete a Person

    private func deleteItem(at index: Int) {
        tempItem.people?.remove(at: index)
    }
}

// MARK: - Person Row View

extension PeopleEditorView {
    private struct PersonRowView: View {
        @Binding
        var person: BaseItemPerson

        var body: some View {
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

                if person.type == PersonKind.actor.rawValue {
                    TextField(L10n.role, text: Binding(
                        get: { person.role ?? "" },
                        set: { person.role = $0 }
                    ))
                    .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - New Person Input View

extension PeopleEditorView {
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
                    TextField(L10n.newWithItem(L10n.people), text: $newPersonName)
                        .font(.headline)
                        .onSubmit { addAction() }

                    Picker(L10n.type, selection: $newPersonType) {
                        ForEach(PersonKind.allCases, id: \.self) { type in
                            Text(type.displayTitle).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    if newPersonType == .actor {
                        TextField(L10n.role, text: $newPersonRole)
                            .onSubmit { addAction() }
                            .foregroundColor(.secondary)
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
