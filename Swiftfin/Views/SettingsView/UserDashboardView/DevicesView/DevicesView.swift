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

struct DevicesView: View {

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    // This exists for some later usage. this can be used to initialize this for a single user. When the UserView is done, there will be a
    // UserDetailView with a "Devices" section. That will vall this same view WITH a userID so it should filter to only that user.
    var userID: String?

    @StateObject
    private var viewModel = DevicesViewModel()

    @State
    private var isPresentingDeleteAllConfirmation = false
    @State
    private var isPresentingDeleteConfirmation = false
    @State
    private var isPresentingSelfDeleteError = false
    @State
    private var selectedDevice: DeviceInfo?
    @State
    private var temporaryDeviceName: String = ""
    @State
    private var deviceToDelete: String?

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(L10n.allDevices)
            .onFirstAppear {
                viewModel.send(.getDevices(userID))
            }
            .topBarTrailing {
                navigationBarView
            }
            .confirmationDialog(
                L10n.deleteAllDevices,
                isPresented: $isPresentingDeleteAllConfirmation,
                titleVisibility: .visible
            ) {
                deleteAllDevicesConfirmationActions
            } message: {
                Text(L10n.deleteAllDevicesWarning)
            }
            .confirmationDialog(
                L10n.deleteDevice,
                isPresented: $isPresentingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                deleteDeviceConfirmationActions
            } message: {
                Text(L10n.deleteDeviceWarning)
            }
            .alert(isPresented: $isPresentingSelfDeleteError) {
                deletionFailureAlert
            }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .content:
            if viewModel.devices.isEmpty {
                Text(L10n.none)
            } else {
                deviceListView
            }
        case let .error(error):
            ErrorView(error: error)
                .onRetry {
                    viewModel.send(.getDevices(userID))
                }
        case .initial:
            DelayedProgressView()
        }
    }

    // MARK: - Navigation Bar Content

    @ViewBuilder
    private var navigationBarView: some View {
        if viewModel.backgroundStates.contains(.gettingDevices) {
            ProgressView()
        } else {
            Button(L10n.deleteAll, role: .destructive) {
                isPresentingDeleteAllConfirmation = true
                UIDevice.impact(.light)
            }
            .buttonStyle(.toolbarPill)
            .disabled(viewModel.devices.isEmpty)
        }
    }

    // MARK: - Device List View

    private var deviceListView: some View {
        List {
            ListTitleSection(
                L10n.devices,
                description: L10n.allDevicesDescription
            ) {
                UIApplication.shared.open(.jellyfinDocsDevices)
            }
            ForEach(Array(viewModel.devices.keys), id: \.self) { id in
                if let deviceBox = viewModel.devices[id] {
                    DeviceRow(box: deviceBox) {
                        if let selectedDevice = deviceBox.value {
                            router.route(to: \.deviceDetails, selectedDevice)
                        }
                    } onDelete: {
                        deviceToDelete = deviceBox.value?.id
                        selectedDevice = deviceBox.value
                        isPresentingDeleteConfirmation = true
                    }
                }
            }
        }
    }

    // MARK: - Delete All Devices Confirmation Actions

    private var deleteAllDevicesConfirmationActions: some View {
        Group {
            Button(L10n.cancel, role: .cancel) {}

            Button(L10n.confirm, role: .destructive) {
                viewModel.send(.deleteDevices(ids: Array(viewModel.devices.keys)))
            }
        }
    }

    // MARK: - Delete Device Confirmation Actions

    private var deleteDeviceConfirmationActions: some View {
        Group {
            Button(L10n.cancel, role: .cancel) {}

            Button(L10n.delete, role: .destructive) {
                if let deviceToDelete = deviceToDelete {
                    if deviceToDelete == viewModel.userSession.client.configuration.deviceID {
                        isPresentingSelfDeleteError = true
                    } else {
                        viewModel.send(.deleteDevice(id: deviceToDelete))
                    }
                }
            }
        }
    }

    // MARK: - Deletion Failure Alert

    private var deletionFailureAlert: Alert {
        Alert(
            title: Text(L10n.deleteDeviceFailed),
            message: Text(L10n.deleteDeviceSelfDeletion(selectedDevice?.name ?? L10n.unknown)),
            dismissButton: .default(Text(L10n.ok))
        )
    }
}
