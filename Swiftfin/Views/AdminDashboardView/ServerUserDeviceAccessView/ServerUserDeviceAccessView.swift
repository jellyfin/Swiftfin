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

struct ServerUserDeviceAccessView: View {

    // MARK: - Environment

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    // MARK: - ViewModel

    @StateObject
    private var viewModel: ServerUserAdminViewModel
    @StateObject
    private var devicesViewModel = DevicesViewModel()

    // MARK: - State Variables

    @State
    private var tempPolicy: UserPolicy
    @State
    private var error: Error?
    @State
    private var isPresentingError: Bool = false

    // MARK: - Current Date

    @CurrentDate
    private var currentDate: Date

    // MARK: - Initializer

    init(viewModel: ServerUserAdminViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.tempPolicy = viewModel.user.policy ?? UserPolicy()
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(L10n.deviceAccess)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismissCoordinator()
            }
            .topBarTrailing {
                if viewModel.backgroundStates.contains(.updating) {
                    ProgressView()
                }
                Button(L10n.save) {
                    if tempPolicy != viewModel.user.policy {
                        viewModel.send(.updatePolicy(tempPolicy))
                    }
                }
                .buttonStyle(.toolbarPill)
                .disabled(viewModel.user.policy == tempPolicy)
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case let .error(eventError):
                    UIDevice.feedback(.error)
                    error = eventError
                    isPresentingError = true
                case .updated:
                    UIDevice.feedback(.success)
                    router.dismissCoordinator()
                }
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
            .onFirstAppear {
                devicesViewModel.send(.getDevices)
            }
    }

    // MARK: - Content View

    @ViewBuilder
    var contentView: some View {
        List {
            Section(L10n.access) {
                Toggle(
                    L10n.enableAllDevices,
                    isOn: $tempPolicy.enableAllDevices.coalesce(false)
                )
            }

            if tempPolicy.enableAllDevices == false {
                Section {
                    ForEach(devicesViewModel.devices, id: \.self) { device in
                        Toggle(
                            isOn: $tempPolicy.enabledDevices
                                .coalesce([])
                                .contains(device.id!)
                        ) {
                            HStack {
                                DevicesView.DeviceRow(device: device) {
                                    if let index = tempPolicy.enabledDevices?.firstIndex(of: device.id!) {
                                        tempPolicy.enabledDevices?.remove(at: index)
                                    } else {
                                        if tempPolicy.enabledDevices == nil {
                                            tempPolicy.enabledDevices = []
                                        }
                                        tempPolicy.enabledDevices?.append(device.id!)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
