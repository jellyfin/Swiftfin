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

// TODO: Enable for CustomNames for Devices with SDK Changes

struct DeviceDetailsView: View {

    // MARK: - Current Date

    @CurrentDate
    private var currentDate: Date

    // MARK: - State & Environment Objects

    @EnvironmentObject
    private var router: AdminDashboardCoordinator.Router

    @StateObject
    private var viewModel: DeviceDetailViewModel

    // MARK: - Custom Name Variable

    @State
    private var temporaryCustomName: String

    // MARK: - Dialog State

    @State
    private var isPresentingSuccess: Bool = false

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Initializer

    init(device: DeviceInfo) {
        _viewModel = StateObject(wrappedValue: DeviceDetailViewModel(device: device))

        // TODO: Enable with SDK Change
        self.temporaryCustomName = device.name ?? "" // device.customName ?? device.name
    }

    // MARK: - Body

    var body: some View {
        List {
            if let userID = viewModel.device.lastUserID,
               let userName = viewModel.device.lastUserName
            {

                let user = UserDto(id: userID, name: userName)

                AdminDashboardView.UserSection(
                    user: user,
                    lastActivityDate: viewModel.device.dateLastActivity
                ) {
                    router.route(to: \.userDetails, user)
                }
            }

            // TODO: Enable with SDK Change
            // CustomDeviceNameSection(customName: $temporaryCustomName)

            AdminDashboardView.DeviceSection(
                client: viewModel.device.appName,
                device: viewModel.device.name,
                version: viewModel.device.appVersion
            )

            CapabilitiesSection(device: viewModel.device)
        }
        .navigationTitle(L10n.device)
        .onReceive(viewModel.events) { event in
            switch event {
            case let .error(eventError):
                UIDevice.feedback(.error)
                error = eventError
            case .setCustomName:
                UIDevice.feedback(.success)
                isPresentingSuccess = true
            }
        }
        .topBarTrailing {
            if viewModel.backgroundStates.contains(.updating) {
                ProgressView()

                // TODO: Enable with SDK Change
                /*
                 Button(L10n.save) {
                     UIDevice.impact(.light)
                     if device.id != nil {
                         viewModel.send(.setCustomName(
                             id: device.id ?? "",
                             newName: temporaryCustomName
                         ))
                     }
                 }
                 .buttonStyle(.toolbarPill)
                 .disabled(temporaryCustomName == device.customName)
                  */
            }
        }
        .alert(
            L10n.success.text,
            isPresented: $isPresentingSuccess
        ) {
            Button(L10n.dismiss, role: .cancel)
        } message: {
            Text(L10n.customDeviceNameSaved(temporaryCustomName))
        }
        .errorMessage($error)
    }
}
