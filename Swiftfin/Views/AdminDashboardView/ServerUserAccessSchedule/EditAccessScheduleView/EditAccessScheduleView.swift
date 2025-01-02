//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct EditAccessScheduleView: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - Observed & Environment Objects

    @EnvironmentObject
    private var router: AdminDashboardCoordinator.Router

    @ObservedObject
    private var viewModel: ServerUserAdminViewModel

    // MARK: - Policy Variable

    @State
    private var selectedSchedules: Set<AccessSchedule> = []

    // MARK: - Dialog States

    @State
    private var isPresentingDeleteSelectionConfirmation = false
    @State
    private var isPresentingDeleteConfirmation = false

    // MARK: - Editing State

    @State
    private var isEditing: Bool = false

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Initializer

    init(viewModel: ServerUserAdminViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(L10n.accessSchedules)
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
                        Button(L10n.cancel) {
                            isEditing.toggle()
                            selectedSchedules.removeAll()
                            UIDevice.impact(.light)
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
                isHidden: isEditing || viewModel.user.policy?.accessSchedules == []
            ) {
                Button(L10n.add, systemImage: "plus") {
                    router.route(to: \.userAddAccessSchedule, viewModel)
                }

                Button(L10n.edit, systemImage: "checkmark.circle") {
                    isEditing = true
                }
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case let .error(eventError):
                    UIDevice.feedback(.error)
                    error = eventError
                case .updated:
                    UIDevice.feedback(.success)
                }
            }
            .confirmationDialog(
                L10n.deleteSelectedSchedules,
                isPresented: $isPresentingDeleteSelectionConfirmation,
                titleVisibility: .visible
            ) {
                deleteSelectedSchedulesConfirmationActions
            } message: {
                Text(L10n.deleteSelectionSchedulesWarning)
            }
            .confirmationDialog(
                L10n.deleteSchedule,
                isPresented: $isPresentingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                deleteScheduleConfirmationActions
            } message: {
                Text(L10n.deleteScheduleWarning)
            }
            .errorMessage($error)
    }

    // MARK: - Content View

    @ViewBuilder
    var contentView: some View {
        List {
            ListTitleSection(
                L10n.accessSchedules.localizedCapitalized,
                description: L10n.accessSchedulesDescription
            ) {
                UIApplication.shared.open(.jellyfinDocsManagingUsers)
            }

            if viewModel.user.policy?.accessSchedules == [] {
                Button(L10n.add) {
                    router.route(to: \.userAddAccessSchedule, viewModel)
                }
            } else {
                ForEach(viewModel.user.policy?.accessSchedules ?? [], id: \.self) { schedule in
                    EditAccessScheduleRow(schedule: schedule) {
                        if isEditing {
                            selectedSchedules.toggle(value: schedule)
                        }
                    } onDelete: {
                        selectedSchedules = [schedule]
                        isPresentingDeleteConfirmation = true
                    }
                    .environment(\.isEditing, isEditing)
                    .environment(\.isSelected, selectedSchedules.contains(schedule))
                }
            }
        }
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
    private var deleteSelectedSchedulesConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.confirm, role: .destructive) {

            var tempPolicy: UserPolicy = viewModel.user.policy!

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
    private var deleteScheduleConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.delete, role: .destructive) {

            var tempPolicy: UserPolicy = viewModel.user.policy!

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
