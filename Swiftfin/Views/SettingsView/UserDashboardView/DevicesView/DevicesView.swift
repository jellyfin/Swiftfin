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
    private var viewModel: DevicesViewModel

    @State
    private var isPresentingDeleteSelectionConfirmation = false
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
    @State
    private var selectMode: Bool = false
    @State
    private var selectedDevices: Set<String> = []

    // MARK: - Initializer

    init(userID: String?) {
        _viewModel = StateObject(wrappedValue: DevicesViewModel(userID))
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(L10n.allDevices)
            .onFirstAppear {
                viewModel.send(.getDevices)
            }
            .topBarTrailing {
                navigationBarView
            }
            .confirmationDialog(
                L10n.deleteSelectedDevices,
                isPresented: $isPresentingDeleteSelectionConfirmation,
                titleVisibility: .visible
            ) {
                deleteSelectedDevicesConfirmationActions
            } message: {
                Text(L10n.deleteSelectionDevicesWarning)
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
                    viewModel.send(.getDevices)
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
            Button(selectMode ? L10n.cancel : L10n.edit) {
                withAnimation {
                    selectMode.toggle()
                    UIDevice.impact(.light)
                    if !selectMode { selectedDevices.removeAll() }
                }
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

            if selectMode {
                Section {
                    Button(selectedDevices == Set(viewModel.devices.keys) ? "Remove All" : "Select All") {
                        withAnimation {
                            if selectedDevices == Set(viewModel.devices.keys) {
                                selectedDevices = []
                            } else {
                                selectedDevices = Set(viewModel.devices.keys)
                            }
                        }
                    }
                    .disabled(!selectMode)
                    .transition(.move(edge: .top).combined(with: .opacity))

                    Button(L10n.deleteDevices, role: .destructive) {
                        isPresentingDeleteSelectionConfirmation = true
                    }
                    .disabled(selectedDevices.isEmpty)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            ForEach(Array(viewModel.devices.keys), id: \.self) { id in
                if let deviceBox = viewModel.devices[id] {
                    DeviceRow(
                        box: deviceBox,
                        onSelect: {
                            if let selectedDevice = deviceBox.value {
                                router.route(to: \.deviceDetails, selectedDevice)
                            }
                        },
                        onDelete: {
                            deviceToDelete = deviceBox.value?.id
                            selectedDevice = deviceBox.value
                            isPresentingDeleteConfirmation = true
                        },
                        selectMode: $selectMode,
                        selected: Binding(
                            get: { selectedDevices.contains(id) },
                            set: { isSelected in
                                withAnimation {
                                    if isSelected {
                                        selectedDevices.insert(id)
                                    } else {
                                        selectedDevices.remove(id)
                                    }
                                }
                            }
                        )
                    )
                }
            }
        }
        .animation(.easeInOut, value: selectMode)
    }

    // MARK: - Delete Selected Devices Confirmation Actions

    private var deleteSelectedDevicesConfirmationActions: some View {
        Group {
            Button(L10n.cancel, role: .cancel) {}

            Button(L10n.confirm, role: .destructive) {
                viewModel.send(.deleteDevices(ids: Array(selectedDevices)))
                selectMode = false
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
                        viewModel.send(.deleteDevices(ids: [deviceToDelete]))
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
