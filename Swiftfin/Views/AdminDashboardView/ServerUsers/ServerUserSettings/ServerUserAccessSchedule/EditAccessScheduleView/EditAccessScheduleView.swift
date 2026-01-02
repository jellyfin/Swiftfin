//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct EditAccessScheduleView: View {

    @Default(.accentColor)
    private var accentColor

    @Router
    private var router

    @ObservedObject
    private var viewModel: ServerUserAdminViewModel

    @State
    private var selectedSchedules: Set<AccessSchedule> = []
    @State
    private var isPresentingDeleteConfirmation = false
    @State
    private var isEditing: Bool = false

    init(viewModel: ServerUserAdminViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        contentView
            .navigationTitle(L10n.accessSchedules.localizedCapitalized)
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
                            isPresentingDeleteConfirmation = true
                        }
                        .buttonStyle(.toolbarPill(.red))
                        .disabled(selectedSchedules.isEmpty)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .navigationBarMenuButton(
                isLoading: viewModel.background.is(.refreshing),
                isHidden: isEditing || viewModel.user.policy?.accessSchedules == []
            ) {
                Button(L10n.add, systemImage: "plus") {
                    router.route(to: .userAddAccessSchedule(viewModel: viewModel))
                }

                Button(L10n.edit, systemImage: "checkmark.circle") {
                    isEditing = true
                }
            }
            .refreshable {
                viewModel.refresh()
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case .updated:
                    UIDevice.feedback(.success)
                }
            }
            .confirmationDialog(
                L10n.delete,
                isPresented: $isPresentingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                deleteConfirmationActions
            } message: {
                Text(L10n.deleteSelectedConfirmation)
            }
            .errorMessage($viewModel.error)
    }

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
                    router.route(to: .userAddAccessSchedule(viewModel: viewModel))
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
                    .isEditing(isEditing)
                    .isSelected(selectedSchedules.contains(schedule))
                }
            }
        }
    }

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

    @ViewBuilder
    private var deleteConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.delete, role: .destructive) {
            var tempPolicy: UserPolicy = viewModel.user.policy!

            tempPolicy.accessSchedules = tempPolicy.accessSchedules?.filter {
                !selectedSchedules.contains($0)
            }

            viewModel.updatePolicy(tempPolicy)
            isEditing = false
            selectedSchedules.removeAll()
        }
    }
}
