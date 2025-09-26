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

    @ObservedObject
    private var viewModel: DevicesViewModel

    @State
    private var temporaryCustomName: String?

    private let device: DeviceInfoDto

    init(device: DeviceInfoDto, viewModel: DevicesViewModel) {
        self.device = device
        self._temporaryCustomName = State(initialValue: device.customName)
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            if let userID = device.lastUserID,
               let userName = device.lastUserName
            {

                let user = UserDto(id: userID, name: userName)

                AdminDashboardView.UserSection(
                    user: user,
                    lastActivityDate: device.dateLastActivity
                ) {
                    router.route(to: .userDetails(user: user))
                }
            }

            Section(L10n.name) {
                TextField(
                    L10n.customName,
                    text: $temporaryCustomName.map(
                        getter: { $0 ?? "" },
                        setter: { $0.isEmpty ? nil : $0 }
                    )
                )
            }

            AdminDashboardView.DeviceSection(
                client: device.appName,
                device: device.name,
                version: device.appVersion
            )

            CapabilitiesSection(device: device)
        }
        .navigationTitle(L10n.device)
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated:
                UIDevice.feedback(.success)
            }
        }
        .topBarTrailing {
            if viewModel.background.is(.updating) {
                ProgressView()
            }
            Button(L10n.save) {
                if let id = device.id {
                    viewModel.update(
                        id: id,
                        options: .init(
                            customName: temporaryCustomName
                        )
                    )
                }
            }
            .buttonStyle(.toolbarPill)
            .disabled(temporaryCustomName == device.customName)
        }
        .errorMessage($viewModel.error)
    }
}
