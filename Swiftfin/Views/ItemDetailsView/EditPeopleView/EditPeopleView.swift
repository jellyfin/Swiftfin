//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import SwiftUI

struct EditPeopleView: View {

    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: ItemDetailsCoordinator.Router

    @ObservedObject
    var viewModel: ItemDetailsViewModel

    @State
    private var isPresentingDeleteConfirmation = false
    @State
    private var isPresentingDeleteSelectionConfirmation = false
    @State
    private var selectedPeople: Set<String> = []
    @State
    private var isEditing: Bool = false

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        contentView
            .navigationBarTitle(L10n.editWithItem(L10n.people))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(isEditing)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isEditing {
                        navigationBarSelectView
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    navigationBarEditView
                }
                ToolbarItem(placement: .bottomBar) {
                    if isEditing {
                        Button(L10n.delete) {
                            isPresentingDeleteSelectionConfirmation = true
                        }
                        .buttonStyle(.toolbarPill(.red))
                        .disabled(selectedPeople.isEmpty)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .confirmationDialog(
                L10n.deleteSelectedPeople,
                isPresented: $isPresentingDeleteSelectionConfirmation,
                titleVisibility: .visible
            ) {
                deleteSelectedPeopleConfirmationActions
            } message: {
                Text(L10n.deleteSelectedPeopleWarning)
            }
            .confirmationDialog(
                L10n.deletePerson,
                isPresented: $isPresentingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                deletePeopleConfirmationActions
            } message: {
                Text(L10n.deletePersonWarning)
            }
    }

    // MARK: - Navigation Bar Select/Remove All Content

    @ViewBuilder
    private var navigationBarSelectView: some View {
        let isAllSelected = selectedPeople.count == viewModel.people.count
        Button(isAllSelected ? L10n.removeAll : L10n.selectAll) {
            selectedPeople = isAllSelected ? [] : Set(viewModel.people.compactMap(\.id))
        }
        .buttonStyle(.toolbarPill)
        .disabled(!isEditing)
        .foregroundStyle(accentColor)
    }

    // MARK: - Navigation Bar Edit Content

    @ViewBuilder
    private var navigationBarEditView: some View {
        if viewModel.state == .refreshing {
            ProgressView()
        }

        if isEditing {
            Button(L10n.cancel) {
                isEditing.toggle()
                UIDevice.impact(.light)
                if !isEditing {
                    selectedPeople.removeAll()
                }
            }
            .buttonStyle(.toolbarPill)
            .foregroundStyle(accentColor)
        } else {
            Menu(L10n.options, systemImage: "ellipsis.circle") {
                Button(L10n.addUser, systemImage: "plus") {
                    router.route(to: \.addPerson, viewModel)
                }

                if viewModel.people.isNotEmpty {
                    Button(L10n.editUsers, systemImage: "checkmark.circle") {
                        isEditing = true
                    }
                }
            }
            .labelStyle(.iconOnly)
            .backport
            .fontWeight(.semibold)
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        List {
            InsetGroupedListHeader(
                L10n.people,
                description: L10n.peopleDescription
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .padding(.vertical, 24)

            if viewModel.people.isNotEmpty {
                ForEach(viewModel.people, id: \.self) { person in
                    if let personID = person.id {
                        EditPeopleRow(person: person) {
                            if isEditing {
                                selectedPeople.toggle(value: personID)
                            }
                        } onDelete: {
                            selectedPeople = [personID]
                            isPresentingDeleteConfirmation = true
                        }
                        .environment(\.isEditing, isEditing)
                        .environment(\.isSelected, selectedPeople.contains(personID))
                        .listRowSeparator(.hidden)
                        .listRowInsets(.zero)
                    }
                }
            } else {
                Text(L10n.none)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.zero)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Delete Selected People Confirmation Actions

    @ViewBuilder
    private var deleteSelectedPeopleConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.confirm, role: .destructive) {
            let peopleToRemove = viewModel.people.filter { selectedPeople.contains($0.id ?? "") }
            viewModel.send(.removePeople(peopleToRemove))
            selectedPeople.removeAll()
            isEditing = false
        }
    }

    // MARK: - Delete Single Person Confirmation Actions

    @ViewBuilder
    private var deletePeopleConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.delete, role: .destructive) {
            if let personToDelete = selectedPeople.first, selectedPeople.count == 1 {
                let person = viewModel.people.first(where: { $0.id == personToDelete })
                if let person {
                    viewModel.send(.removePeople([person]))
                }
                selectedPeople.removeAll()
                isEditing = false
            }
        }
    }
}
