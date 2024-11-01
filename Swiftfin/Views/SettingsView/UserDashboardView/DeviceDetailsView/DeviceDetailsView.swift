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

// TODO: Enable for CustomNames for Devices with SDK Changes

struct DeviceDetailsView: View {

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @CurrentDate
    private var currentDate: Date

    @State
    private var temporaryCustomName: String
    @State
    private var error: Error?
    @State
    private var isPresentingError: Bool = false
    @State
    private var isPresentingSuccess: Bool = false

    @StateObject
    private var viewModel: DeviceDetailViewModel

    private var device: DeviceInfo {
        viewModel.device
    }

    // MARK: - Initializer

    init(device: DeviceInfo) {
        _viewModel = StateObject(wrappedValue: DeviceDetailViewModel(device: device))

        // TODO: Enable with SDK Change
        self.temporaryCustomName = device.name ?? "" // device.customName ?? device.name

//        _viewModel = StateObject(wrappedValue: DevicesViewModel(device.lastUserID))
    }

    // MARK: - Body

    var body: some View {
        List {
            if let userID = device.lastUserID,
               let userName = device.lastUserName
            {

                let user = UserDto(id: userID, name: userName)

                UserDashboardView.UserSection(
                    user: user,
                    lastActivityDate: device.dateLastActivity
                ) {
                    router.route(to: \.userDetails, user)
                }
            }

            // TODO: Enable with SDK Change
            // CustomDeviceNameSection(customName: $temporaryCustomName)

            UserDashboardView.DeviceSection(
                client: device.appName,
                device: device.name,
                version: device.appVersion
            )

            CapabilitiesSection(device: device)
        }
        .navigationTitle(L10n.device)
        .onReceive(viewModel.events) { event in
            switch event {
            case let .error(eventError):
                UIDevice.feedback(.error)
                error = eventError
                isPresentingError = true
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
            L10n.error.text,
            isPresented: $isPresentingError,
            presenting: error
        ) { _ in
            Button(L10n.dismiss, role: .cancel)
        } message: { error in
            Text(error.localizedDescription)
        }
        .alert(
            L10n.success.text,
            isPresented: $isPresentingSuccess
        ) {
            Button(L10n.dismiss, role: .cancel)
        } message: {
            Text(L10n.customDeviceNameSaved(temporaryCustomName))
        }
    }
}
