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

struct ServerUserDeviceAccessView: View {

    // MARK: - Current Date

    @CurrentDate
    private var currentDate: Date

    // MARK: - State & Environment Objects

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @StateObject
    private var viewModel: ServerUserAdminViewModel
    @StateObject
    private var devicesViewModel = DevicesViewModel()

    // MARK: - State Variables

    @State
    private var tempPolicy: UserPolicy

    // MARK: - Error State

    @State
    private var error: Error?

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
                case .updated:
                    UIDevice.feedback(.success)
                    router.dismissCoordinator()
                }
            }
            .onFirstAppear {
                devicesViewModel.send(.refresh)
            }
            .errorMessage($error)
    }

    // MARK: - Content View

    @ViewBuilder
    var contentView: some View {
        List {
            InsetGroupedListHeader {
                Toggle(
                    L10n.enableAllDevices,
                    isOn: $tempPolicy.enableAllDevices.coalesce(false)
                )
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .padding(.vertical, 24)

            if tempPolicy.enableAllDevices == false {
                Section {
                    ForEach(devicesViewModel.devices, id: \.self) { device in
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
                        .environment(\.isEditing, true)
                        .environment(\.isSelected, tempPolicy.enabledDevices?.contains(device.id ?? "") == true)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}
