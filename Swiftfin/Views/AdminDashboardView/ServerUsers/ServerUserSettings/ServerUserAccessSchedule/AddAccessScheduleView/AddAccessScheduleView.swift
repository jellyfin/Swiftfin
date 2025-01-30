//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct AddAccessScheduleView: View {

    // MARK: - Observed & Environment Objects

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @ObservedObject
    private var viewModel: ServerUserAdminViewModel

    // MARK: - Access Schedule Variables

    @State
    private var tempPolicy: UserPolicy
    @State
    private var selectedDay: DynamicDayOfWeek = .everyday
    @State
    private var startTime: Date = Calendar.current.startOfDay(for: Date())
    @State
    private var endTime: Date = Calendar.current.startOfDay(for: Date()).addingTimeInterval(+3600)

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Initializer

    init(viewModel: ServerUserAdminViewModel) {
        self.viewModel = viewModel
        self.tempPolicy = viewModel.user.policy!
    }

    private var isValidRange: Bool {
        startTime < endTime
    }

    private var newSchedule: AccessSchedule? {
        guard isValidRange else { return nil }

        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        guard let startHour = startComponents.hour,
              let startMinute = startComponents.minute,
              let endHour = endComponents.hour,
              let endMinute = endComponents.minute
        else {
            return nil
        }

        // AccessSchedule Hours are formatted as 23.5 == 11:30pm or 8.25 == 8:15am
        let startDouble = Double(startHour) + Double(startMinute) / 60.0
        let endDouble = Double(endHour) + Double(endMinute) / 60.0

        // AccessSchedule should have valid Start & End Hours
        let newSchedule = AccessSchedule(
            dayOfWeek: selectedDay,
            endHour: endDouble,
            startHour: startDouble,
            userID: viewModel.user.id
        )

        return newSchedule
    }

    private var isDuplicateSchedule: Bool {
        guard let newSchedule, let existingSchedules = viewModel.user.policy?.accessSchedules else {
            return false
        }

        return existingSchedules.contains { other in
            other.dayOfWeek == selectedDay &&
                other.startHour == newSchedule.startHour &&
                other.endHour == newSchedule.endHour
        }
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(L10n.addAccessSchedule.localizedCapitalized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismissCoordinator()
            }
            .topBarTrailing {
                if viewModel.backgroundStates.contains(.refreshing) {
                    ProgressView()
                }
                if viewModel.backgroundStates.contains(.updating) {
                    Button(L10n.cancel) {
                        viewModel.send(.cancel)
                    }
                    .buttonStyle(.toolbarPill(.red))
                } else {
                    Button(L10n.save) {
                        saveSchedule()
                    }
                    .buttonStyle(.toolbarPill)
                    .disabled(!isValidRange)
                }
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case let .error(eventError):
                    UIDevice.feedback(.error)
                    error = eventError
                case .updated:
                    UIDevice.feedback(.success)
                    router.dismissCoordinator()
                }
            }
            .errorMessage($error)
    }

    // MARK: - Content View

    private var contentView: some View {
        Form {
            Section(L10n.dayOfWeek) {
                Picker(L10n.dayOfWeek, selection: $selectedDay) {
                    ForEach(DynamicDayOfWeek.allCases, id: \.self) { day in

                        if day == .everyday {
                            Divider()
                        }

                        Text(day.displayTitle).tag(day)
                    }
                }
            }

            Section(L10n.startTime) {
                DatePicker(L10n.startTime, selection: $startTime, displayedComponents: .hourAndMinute)
            }

            Section {
                DatePicker(L10n.endTime, selection: $endTime, displayedComponents: .hourAndMinute)
            } header: {
                Text(L10n.endTime)
            } footer: {
                if !isValidRange {
                    Label(L10n.accessScheduleInvalidTime, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }

                if isDuplicateSchedule {
                    Label(L10n.scheduleAlreadyExists, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }
        }
    }

    // MARK: - Save Schedule

    private func saveSchedule() {

        guard isValidRange, let newSchedule else {
            error = JellyfinAPIError(L10n.accessScheduleInvalidTime)
            return
        }

        guard !isDuplicateSchedule else {
            error = JellyfinAPIError(L10n.scheduleAlreadyExists)
            return
        }

        tempPolicy.accessSchedules = tempPolicy.accessSchedules
            .appendedOrInit(newSchedule)

        viewModel.send(.updatePolicy(tempPolicy))
    }
}
