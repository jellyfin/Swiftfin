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

// TODO: Replace with CustomName when Available

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
    private var selectedDevices: Set<String> = []
    @State
    private var editMode: Bool = false

    // MARK: - Initializer

    init(userID: String?) {
        _viewModel = StateObject(wrappedValue: DevicesViewModel(userID))
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(L10n.allDevices)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(editMode)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if editMode {
                        navigationBarSelectView
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
        VStack {
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
                            if editMode {
                                if selectedDevices.contains(id) {
                                    selectedDevices.remove(id)
                                } else {
                                    selectedDevices.insert(id)
                                }
                            } else if let selectedDevice = deviceBox.value {
                                router.route(to: \.deviceDetails, selectedDevice)
                            }
                        } onDelete: {
                            selectedDevices.removeAll()
                            selectedDevices.insert(id)
                            isPresentingDeleteConfirmation = true
                        }
                        .environment(\.isEditing, editMode)
                        .environment(\.isSelected, selectedDevices.contains(id))
                    }
                }
            }

            if editMode {
                deleteDevicesButton
                    .edgePadding([.bottom, .horizontal])
            }
        }
    }

    // MARK: - Button to Delete Devices

    @ViewBuilder
    private var deleteDevicesButton: some View {
        Button {
            isPresentingDeleteSelectionConfirmation = true
        } label: {
            ZStack {
                Color.red

                Text("Delete")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(selectedDevices.isNotEmpty ? .primary : .secondary)

                if selectedDevices.isEmpty {
                    Color.black
                        .opacity(0.5)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .frame(height: 50)
            .frame(maxWidth: 400)
        }
        .disabled(selectedDevices.isEmpty)
        .buttonStyle(.plain)
    }

    // MARK: - Navigation Bar Edit Content

    @ViewBuilder
    private var navigationBarEditView: some View {
        if viewModel.backgroundStates.contains(.gettingDevices) {
            ProgressView()
        } else {
            Button(editMode ? L10n.cancel : L10n.edit) {
                editMode.toggle()
                UIDevice.impact(.light)
                if !editMode {
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
        .disabled(!editMode)
    }

    // MARK: - Delete Selected Devices Confirmation Actions

    private var deleteSelectedDevicesConfirmationActions: some View {
        Group {
            Button(L10n.cancel, role: .cancel) {}

            Button(L10n.confirm, role: .destructive) {
                viewModel.send(.deleteDevices(ids: Array(selectedDevices)))
                editMode = false
                selectedDevices.removeAll()
            }
        }
    }

    // MARK: - Delete Device Confirmation Actions

    private var deleteDeviceConfirmationActions: some View {
        Group {
            Button(L10n.cancel, role: .cancel) {}

            Button(L10n.delete, role: .destructive) {
                if let deviceToDelete = selectedDevices.first, selectedDevices.count == 1 {
                    if deviceToDelete == viewModel.userSession.client.configuration.deviceID {
                        isPresentingSelfDeleteError = true
                    } else {
                        viewModel.send(.deleteDevices(ids: [deviceToDelete]))
                        selectedDevices.removeAll()
                    }
                }
            }
        }
    }

    // MARK: - Deletion Failure Alert

    private var deletionFailureAlert: Alert {
        selectedDevices.removeAll()

        return Alert(
            title: Text(L10n.deleteDeviceFailed),
            // TODO: Replace with CustomName when Available
            message: Text(L10n.deleteDeviceSelfDeletion(viewModel.userSession.client.configuration.deviceName)),
            dismissButton: .default(Text(L10n.ok))
        )
    }
}
