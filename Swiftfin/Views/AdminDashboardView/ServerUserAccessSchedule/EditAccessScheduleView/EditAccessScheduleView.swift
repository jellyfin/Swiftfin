//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct EditAccessScheduleView: View {

    @Default(.accentColor)
    private var accentColor

    // MARK: - Environment

    @EnvironmentObject
    private var router: AdminDashboardCoordinator.Router

    // MARK: - ViewModel

    @ObservedObject
    private var viewModel: ServerUserAdminViewModel

    // MARK: - State Variables

    @State
    private var isPresentingDeleteSelectionConfirmation = false
    @State
    private var isPresentingDeleteConfirmation = false
    @State
    private var isPresentingSelfDeleteError = false
    @State
    private var selectedSchedules: Set<AccessSchedule> = []
    @State
    private var isEditing: Bool = false

    @State
    private var error: Error?
    @State
    private var isPresentingError: Bool = false

    @State
    private var tempPolicy: UserPolicy

    // MARK: - Initializer

    init(viewModel: ServerUserAdminViewModel) {
        self.viewModel = viewModel
        self.tempPolicy = viewModel.user.policy ?? UserPolicy()
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(L10n.schedules)
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
                                selectedSchedules.removeAll()
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
                        .disabled(selectedSchedules.isEmpty)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .navigationBarMenuButton(
                isLoading: viewModel.backgroundStates.contains(.refreshing),
                isHidden: isEditing
            ) {
                Button("addSchedule", systemImage: "plus") {
                    // router.route(to: \.addServerUser)
                }

                if viewModel.user.policy?.accessSchedules != [] {
                    Button("editSchedule", systemImage: "checkmark.circle") {
                        isEditing = true
                    }
                }
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case let .error(eventError):
                    UIDevice.feedback(.error)
                    error = eventError
                    isPresentingError = true
                case .updated:
                    UIDevice.feedback(.success)
                }
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
            .alert(
                L10n.error.text,
                isPresented: $isPresentingError,
                presenting: error
            ) { _ in
                Button(L10n.dismiss, role: .cancel) {}
            } message: { error in
                Text(error.localizedDescription)
            }
    }

    // MARK: - Content View

    @ViewBuilder
    var contentView: some View {
        List {
            InsetGroupedListHeader(
                L10n.accessSchedules.localizedCapitalized,
                description: L10n.accessSchedulesDescription
            ) {
                UIApplication.shared.open(.jellyfinDocsManagingUsers)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .padding(.vertical, 24)

            if viewModel.user.policy?.accessSchedules == [] {
                Text(L10n.none)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.zero)
            } else {
                ForEach(viewModel.user.policy?.accessSchedules ?? [], id: \.self) { schedule in
                    EditAccessScheduleRow(schedule: schedule) {
                        if isEditing {
                            selectedSchedules.toggle(value: schedule)
                        } else {
                            // router.route(to: \.userDetails, user)
                        }
                    } onDelete: {
                        selectedSchedules.removeAll()
                        selectedSchedules.insert(schedule)
                        isPresentingDeleteConfirmation = true
                    }
                    .environment(\.isEditing, isEditing)
                    .environment(\.isSelected, selectedSchedules.contains(schedule))
                    .listRowInsets(.edgeInsets)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Navigation Bar Select/Remove All Content

    @ViewBuilder
    private var navigationBarSelectView: some View {

        let isAllSelected: Bool = selectedSchedules.count == viewModel.user.policy?.accessSchedules?.count

        Button(isAllSelected ? L10n.removeAll : L10n.selectAll) {
            if isAllSelected {
                selectedSchedules = []
            } else {
                selectedSchedules = Set(viewModel.user.policy?.accessSchedules ?? [])
            }
        }
        .buttonStyle(.toolbarPill)
        .disabled(!isEditing)
        .foregroundStyle(accentColor)
    }

    // MARK: - Delete Selected Schedules Confirmation Actions

    @ViewBuilder
    private var deleteSelectedUsersConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.confirm, role: .destructive) {
            if selectedSchedules.isNotEmpty {
                tempPolicy.accessSchedules = tempPolicy.accessSchedules?.filter { !selectedSchedules.contains($0)
                }
                viewModel.send(.updatePolicy(tempPolicy))
                isEditing = false
                selectedSchedules.removeAll()
            }
        }
    }

    // MARK: - Delete Schedule Confirmation Actions

    @ViewBuilder
    private var deleteUserConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.delete, role: .destructive) {
            if let scheduleToDelete = selectedSchedules.first,
               selectedSchedules.count == 1
            {

                tempPolicy.accessSchedules = tempPolicy.accessSchedules?.filter {
                    $0 != scheduleToDelete
                }
                viewModel.send(.updatePolicy(tempPolicy))
                isEditing = false
                selectedSchedules.removeAll()
            }
        }
    }
}
