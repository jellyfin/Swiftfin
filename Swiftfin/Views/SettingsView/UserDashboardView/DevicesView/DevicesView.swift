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
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(selectMode)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectMode {
                        navigationBarSelectView
                    }
                }
                ToolbarItem(placement: .principal) {
                    if selectMode {
                        navigationBarDeleteView
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    navigationBarEditView
                }
            }
            .onFirstAppear {
                viewModel.send(.getDevices)
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

    // MARK: - Navigation Bar Edit Content

    @ViewBuilder
    private var navigationBarEditView: some View {
        if viewModel.backgroundStates.contains(.gettingDevices) {
            ProgressView()
        } else {
            Button(selectMode ? L10n.cancel : L10n.edit) {
                selectMode.toggle()
                UIDevice.impact(.light)
                if !selectMode {
                    selectedDevices.removeAll()
                }
            }
            .buttonStyle(.toolbarPill)
        }
    }

    // MARK: - Navigation Bar Select/Remove All Content

    @ViewBuilder
    private var navigationBarSelectView: some View {
        Button(selectedDevices == Set(viewModel.devices.keys) ? L10n.removeAll : L10n.selectAll) {
            if selectedDevices == Set(viewModel.devices.keys) {
                selectedDevices = []
            } else {
                selectedDevices = Set(viewModel.devices.keys)
            }
        }
        .buttonStyle(.toolbarPill)
        .disabled(!selectMode)
    }

    // MARK: - Navigation Bar Delete All

    @ViewBuilder
    private var navigationBarDeleteView: some View {
        Button(L10n.delete, role: .destructive) {
            isPresentingDeleteSelectionConfirmation = true
        }
        .buttonStyle(.toolbarPill)
        .disabled(selectedDevices.isEmpty)
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
