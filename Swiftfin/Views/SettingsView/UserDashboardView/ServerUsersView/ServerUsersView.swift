//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import JellyfinAPI
import SwiftUI

struct ServerUsersView: View {

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @StateObject
    private var viewModel = ServerUsersViewModel()

    @State
    private var isPresentingDeleteSelectionConfirmation = false
    @State
    private var isPresentingDeleteConfirmation = false
    @State
    private var isPresentingSelfDeleteError = false
    @State
    private var selectedUsers: Set<String> = []
    @State
    private var isEditing: Bool = false

    @State
    private var includeHidden: Bool = true
    @State
    private var includeDisabled: Bool = true

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                if viewModel.users.isEmpty {
                    emptyListView
                } else {
                    userListView
                }
            case let .error(error):
                errorView(with: error)
            case .initial:
                DelayedProgressView()
            }
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .navigationTitle(L10n.devices)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isEditing)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if isEditing {
                    navigationBarSelectView
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.users.isNotEmpty {
                    navigationBarEditView
                }
            }
        }
        .onFirstAppear {
            viewModel.send(.getUsers(
                includeHidden: includeHidden,
                includeDisabled: includeDisabled
            ))
        }
        .confirmationDialog(
            L10n.deleteSelectedUsers,
            isPresented: $isPresentingDeleteSelectionConfirmation,
            titleVisibility: .visible
        ) {
            deleteSelectedDevicesConfirmationActions
        } message: {
            Text(L10n.deleteSelectionUsersWarning)
        }
        .confirmationDialog(
            L10n.deleteUser,
            isPresented: $isPresentingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            deleteDeviceConfirmationActions
        } message: {
            Text(L10n.deleteUserWarning)
        }
        .alert(L10n.deleteUserFailed, isPresented: $isPresentingSelfDeleteError) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            Text(L10n.deleteUserSelfDeletion(viewModel.userSession.user.username))
        }
    }

    @ViewBuilder
    private var emptyListView: some View {
        List {
            InsetGroupedListHeader(
                L10n.users,
                description: L10n.allUsersDescription
            ) {
                UIApplication.shared.open(.jellyfinDocsUsers)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .padding(.vertical, 24)

            listMenuView

            HStack {
                Spacer()
                Text(L10n.none)
                Spacer()
            }
            .listRowSeparator(.hidden)
            .listRowInsets(.zero)
        }
        .listStyle(.plain)
    }

    // MARK: - User List View

    @ViewBuilder
    private var userListView: some View {
        VStack {
            List {
                InsetGroupedListHeader(
                    L10n.users,
                    description: L10n.allUsersDescription
                ) {
                    UIApplication.shared.open(.jellyfinDocsUsers)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .padding(.vertical, 24)

                listMenuView

                ForEach(viewModel.users, id: \.self) { user in
                    if let userID = user.id {
                        ServerUsersRow(user: user) {
                            if isEditing {
                                if selectedUsers.contains(userID) {
                                    selectedUsers.remove(userID)
                                } else {
                                    selectedUsers.insert(userID)
                                }
                            } else {
                                router.route(to: \.userDetails, user)
                            }
                        } onDelete: {
                            selectedUsers.removeAll()
                            selectedUsers.insert(userID)
                            isPresentingDeleteConfirmation = true
                        }
                        .environment(\.isEditing, isEditing)
                        .environment(\.isSelected, selectedUsers.contains(userID))
                        .listRowSeparator(.hidden)
                        .listRowInsets(.zero)
                    }
                }
            }
            .listStyle(.plain)

            if isEditing {
                deleteUsersButton
                    .edgePadding([.bottom, .horizontal])
            }
        }
    }

    // MARK: - Button to Delete Devices

    @ViewBuilder
    private var deleteUsersButton: some View {
        Button {
            isPresentingDeleteSelectionConfirmation = true
        } label: {
            ZStack {
                Color.red

                Text(L10n.delete)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(selectedUsers.isNotEmpty ? .primary : .secondary)

                if selectedUsers.isEmpty {
                    Color.black
                        .opacity(0.5)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .frame(height: 50)
            .frame(maxWidth: 400)
        }
        .disabled(selectedUsers.isEmpty)
        .buttonStyle(.plain)
    }

    // MARK: - Error View

    @ViewBuilder
    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.send(.getUsers(includeHidden: includeHidden, includeDisabled: includeDisabled))
            }
    }

    // MARK: - List Menu

    private var listMenuView: some View {
        HStack {
            Menu {
                Toggle(L10n.hidden, systemImage: "eye.slash", isOn: $includeHidden)
                    .onChange(of: includeHidden) { newValue in
                        viewModel.send(.getUsers(
                            includeHidden: newValue,
                            includeDisabled: includeDisabled
                        ))
                    }

                Toggle(L10n.disabled, systemImage: "person.slash", isOn: $includeDisabled)
                    .onChange(of: includeDisabled) { newValue in
                        viewModel.send(.getUsers(
                            includeHidden: includeHidden,
                            includeDisabled: newValue
                        ))
                    }
            } label: {
                HStack {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    L10n.filters.text
                }
                .font(.subheadline.bold())
            }

            Spacer()

            Button {
                router.route(to: \.userCreation, viewModel)
            }
            label: {
                HStack {
                    L10n.add.text
                    Image(systemName: "plus")
                }
                .font(.subheadline.bold())
            }
        }
        .foregroundStyle(Color.accentColor)
    }

    // MARK: - Navigation Bar Edit Content

    @ViewBuilder
    private var navigationBarEditView: some View {
        if viewModel.backgroundStates.contains(.gettingUsers) {
            ProgressView()
        } else {
            Button(isEditing ? L10n.cancel : L10n.edit) {
                isEditing.toggle()
                UIDevice.impact(.light)
                if !isEditing {
                    selectedUsers.removeAll()
                }
            }
            .buttonStyle(.toolbarPill)
        }
    }

    // MARK: - Navigation Bar Select/Remove All Content

    @ViewBuilder
    private var navigationBarSelectView: some View {
        let isAllSelected: Bool = selectedUsers.count == viewModel.users.count

        Button(isAllSelected ? L10n.removeAll : L10n.selectAll) {
            if isAllSelected {
                selectedUsers = []
            } else {
                selectedUsers = Set(viewModel.users.compactMap(\.id))
            }
        }
        .buttonStyle(.toolbarPill)
        .disabled(!isEditing)
    }

    // MARK: - Delete Selected Devices Confirmation Actions

    @ViewBuilder
    private var deleteSelectedDevicesConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.confirm, role: .destructive) {
            viewModel.send(.deleteUsers(Array(selectedUsers)))
            isEditing = false
            selectedUsers.removeAll()
        }
    }

    // MARK: - Delete Device Confirmation Actions

    @ViewBuilder
    private var deleteDeviceConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.delete, role: .destructive) {
            if let deviceToDelete = selectedUsers.first, selectedUsers.count == 1 {
                if deviceToDelete == viewModel.userSession.user.id {
                    isPresentingSelfDeleteError = true
                } else {
                    viewModel.send(.deleteUsers([deviceToDelete]))
                    selectedUsers.removeAll()
                }
            }
        }
    }
}
