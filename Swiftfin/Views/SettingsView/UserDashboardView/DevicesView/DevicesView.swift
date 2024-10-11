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

    @StateObject
    private var viewModel = DevicesViewModel()

    @State
    private var isPresentingDeleteAllConfirmation = false
    @State
    private var isPresentingDeleteConfirmation = false
    @State
    private var isPresentingRenameAlert = false
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
        Group {
            mainContentView
        }
        .navigationTitle(L10n.activeDevices)
        .onFirstAppear {
            viewModel.send(.getDevices)
        }
        .topBarTrailing {
            topBarContent
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
        .alert(L10n.customDeviceName, isPresented: $isPresentingRenameAlert) {
            customDeviceNameAlert
        } message: {
            Text(L10n.enterCustomDeviceName)
        }
    }

    // MARK: - Main Content View

    private var mainContentView: some View {
        Group {
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
                        viewModel.send(.getDevices)
                    }
            case .initial:
                DelayedProgressView()
            }
        }
    }

    // MARK: - Top Bar Content

    private var topBarContent: some View {
        Group {
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
    }

    // MARK: - Device List View

    private var deviceListView: some View {
        List {
            ListTitleSection(
                L10n.devices,
                description: L10n.allDevicesDescription
            ) {
                UIApplication.shared.open(URL(string: "https://jellyfin.org/docs/general/server/devices")!)
            }
            ForEach(Array(viewModel.devices.keys), id: \.self) { id in
                if let deviceBox = viewModel.devices[id] {
                    DeviceRow(box: deviceBox) {
                        selectedDevice = deviceBox.value
                        temporaryDeviceName = selectedDevice?.name ?? ""
                        isPresentingRenameAlert = true
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
                viewModel.send(.deleteAllDevices)
            }
        }
    }

    // MARK: - Delete Device Confirmation Actions

    private var deleteDeviceConfirmationActions: some View {
        Group {
            Button(L10n.cancel, role: .cancel) {}

            Button(L10n.delete, role: .destructive) {
                if let deviceToDelete = deviceToDelete {
                    viewModel.send(.deleteDevice(id: deviceToDelete))

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if viewModel.devices[deviceToDelete] != nil {
                            isPresentingSelfDeleteError = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Rename Custom Device Name Alert

    private var customDeviceNameAlert: some View {
        Group {
            TextField(L10n.name, text: $temporaryDeviceName)
                .keyboardType(.default)

            Button(L10n.save) {
                if let deviceId = selectedDevice?.id {
                    viewModel.send(.setCustomName(id: deviceId, newName: temporaryDeviceName))
                }
                isPresentingRenameAlert = false
            }

            Button(L10n.cancel, role: .cancel) {
                isPresentingRenameAlert = false
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
