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

struct DeviceDetailsView: View {

    @CurrentDate
    private var currentDate: Date

    @Router
    private var router

    @StateObject
    private var viewModel: DeviceDetailViewModel

    @State
    private var temporaryCustomName: String = ""

    init(device: DeviceInfoDto) {
        _viewModel = StateObject(wrappedValue: DeviceDetailViewModel(device: device))
    }

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
                    router.route(to: .userDetails(user: user))
                }
            }

            Section(L10n.name) {
                TextField(
                    L10n.customName,
                    text: $temporaryCustomName
                )
            }

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
            case .updatedCustomName:
                UIDevice.feedback(.success)
            }
        }
        .topBarTrailing {
            if viewModel.backgroundStates.contains(.updating) {
                ProgressView()
            }
            Button(L10n.save) {
                viewModel.setCustomName(temporaryCustomName)
            }
            .buttonStyle(.toolbarPill)
            .disabled(temporaryCustomName.isEmpty)
        }
        .errorMessage($viewModel.error)
    }
}
