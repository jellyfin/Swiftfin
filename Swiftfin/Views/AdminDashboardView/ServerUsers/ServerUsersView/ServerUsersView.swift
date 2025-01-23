//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import JellyfinAPI
import SwiftUI

struct ServerUsersView: View {

    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: AdminDashboardCoordinator.Router

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
    private var isHiddenFilterActive: Bool = false
    @State
    private var isDisabledFilterActive: Bool = false

    @StateObject
    private var viewModel = ServerUsersViewModel()

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                userListView
            case let .error(error):
                errorView(with: error)
            case .initial:
                DelayedProgressView()
            }
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .navigationTitle(L10n.users)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isEditing)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if isEditing {
                    navigationBarSelectView
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if isEditing {
                    Button(isEditing ? L10n.cancel : L10n.edit) {
                        isEditing.toggle()

                        UIDevice.impact(.light)

                        if !isEditing {
                            selectedUsers.removeAll()
                        }
                    }
                    .buttonStyle(.toolbarPill)
                    .foregroundStyle(accentColor)
                }
            }
            ToolbarItem(placement: .bottomBar) {
                if isEditing {
                    Button(L10n.delete) {
                        isPresentingDeleteSelectionConfirmation = true
                    }
                    .buttonStyle(.toolbarPill(.red))
                    .disabled(selectedUsers.isEmpty)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .navigationBarMenuButton(
            isLoading: viewModel.backgroundStates.contains(.gettingUsers),
            isHidden: isEditing
        ) {
            Button(L10n.addUser, systemImage: "plus") {
                router.route(to: \.addServerUser)
            }

            if viewModel.users.isNotEmpty {
                Button(L10n.editUsers, systemImage: "checkmark.circle") {
                    isEditing = true
                }
            }

            Divider()

            Section(L10n.filters) {
                Toggle(L10n.hidden, systemImage: "eye.slash", isOn: $isHiddenFilterActive)
                Toggle(L10n.disabled, systemImage: "person.slash", isOn: $isDisabledFilterActive)
            }
        }

        .onChange(of: isDisabledFilterActive) { newValue in
            viewModel.send(.getUsers(
                isHidden: isHiddenFilterActive,
                isDisabled: newValue
            ))
        }
        .onChange(of: isHiddenFilterActive) { newValue in
            viewModel.send(.getUsers(
                isHidden: newValue,
                isDisabled: isDisabledFilterActive
            ))
        }
        .onFirstAppear {
            viewModel.send(.getUsers())
        }
        .confirmationDialog(
            L10n.deleteSelectedUsers,
            isPresented: $isPresentingDeleteSelectionConfirmation,
            titleVisibility: .visible
        ) {
            deleteSelectedUsersConfirmationActions
        } message: {
            Text(L10n.deleteSelectionUsersWarning)
        }
        .confirmationDialog(
            L10n.deleteUser,
            isPresented: $isPresentingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            deleteUserConfirmationActions
        } message: {
            Text(L10n.deleteUserWarning)
        }
        .alert(L10n.deleteUserFailed, isPresented: $isPresentingSelfDeleteError) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            Text(L10n.deleteUserSelfDeletion(viewModel.userSession.user.username))
        }
        .onNotification(.didAddServerUser) { newUser in
            viewModel.send(.appendUser(newUser))
            router.route(to: \.userDetails, newUser)
        }
    }

    // MARK: - User List View

    @ViewBuilder
    private var userListView: some View {
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

            if viewModel.users.isEmpty {
                Text(L10n.none)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.zero)
            } else {
                ForEach(viewModel.users, id: \.self) { user in
                    if let userID = user.id {
                        ServerUsersRow(user: user) {
                            if isEditing {
                                selectedUsers.toggle(value: userID)
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
                        .listRowInsets(.edgeInsets)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Error View

    @ViewBuilder
    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.send(.getUsers(isHidden: isHiddenFilterActive, isDisabled: isDisabledFilterActive))
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
        .foregroundStyle(accentColor)
    }

    // MARK: - Delete Selected Users Confirmation Actions

    @ViewBuilder
    private var deleteSelectedUsersConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.confirm, role: .destructive) {
            viewModel.send(.deleteUsers(Array(selectedUsers)))
            isEditing = false
            selectedUsers.removeAll()
        }
    }

    // MARK: - Delete User Confirmation Actions

    @ViewBuilder
    private var deleteUserConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.delete, role: .destructive) {
            if let userToDelete = selectedUsers.first, selectedUsers.count == 1 {
                if userToDelete == viewModel.userSession.user.id {
                    isPresentingSelfDeleteError = true
                } else {
                    viewModel.send(.deleteUsers([userToDelete]))
                    selectedUsers.removeAll()
                }
            }
        }
    }
}
