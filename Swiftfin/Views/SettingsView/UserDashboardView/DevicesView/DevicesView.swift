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

    @State
    private var isPresentingDeleteSelectionConfirmation = false
    @State
    private var isPresentingDeleteConfirmation = false
    @State
    private var isPresentingSelfDeleteError = false
    @State
    private var selectedDevices: Set<String> = []
    @State
    private var isEditing: Bool = false

    @StateObject
    private var viewModel: DevicesViewModel

    // MARK: - Initializer

    init(userID: String? = nil) {
        _viewModel = StateObject(wrappedValue: DevicesViewModel(userID))
    }

    // MARK: - Body

    var body: some View {
        ZStack {
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
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .navigationTitle(L10n.devices)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isEditing)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if isEditing {
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
        .alert(L10n.deleteDeviceFailed, isPresented: $isPresentingSelfDeleteError) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            Text(L10n.deleteDeviceSelfDeletion(viewModel.userSession.client.configuration.deviceName))
        }
    }

    // MARK: - Device List View

    @ViewBuilder
    private var deviceListView: some View {
        VStack {
            List {
                InsetGroupedListHeader(
                    L10n.devices,
                    description: L10n.allDevicesDescription
                ) {
                    UIApplication.shared.open(.jellyfinDocsDevices)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .padding(.vertical, 24)

                ForEach(viewModel.devices.keys, id: \.self) { id in
                    if let deviceBox = viewModel.devices[id] {
                        DeviceRow(box: deviceBox) {
                            if isEditing {
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
                        .environment(\.isEditing, isEditing)
                        .environment(\.isSelected, selectedDevices.contains(id))
                        .listRowSeparator(.hidden)
                        .listRowInsets(.zero)
                    }
                }
            }
            .listStyle(.plain)

            if isEditing {
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

                Text(L10n.delete)
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
            Button(isEditing ? L10n.cancel : L10n.edit) {
                isEditing.toggle()
                UIDevice.impact(.light)
                if !isEditing {
                    selectedDevices.removeAll()
                }
            }
            .buttonStyle(.toolbarPill)
        }
    }

    // MARK: - Navigation Bar Select/Remove All Content

    @ViewBuilder
    private var navigationBarSelectView: some View {
        let isAllSelected: Bool = selectedDevices.count == viewModel.devices.count

        Button(isAllSelected ? L10n.removeAll : L10n.selectAll) {
            if isAllSelected {
                selectedDevices = []
            } else {
                selectedDevices = Set(viewModel.devices.keys)
            }
        }
        .buttonStyle(.toolbarPill)
        .disabled(!isEditing)
    }

    // MARK: - Delete Selected Devices Confirmation Actions

    @ViewBuilder
    private var deleteSelectedDevicesConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.confirm, role: .destructive) {
            viewModel.send(.deleteDevices(ids: Array(selectedDevices)))
            isEditing = false
            selectedDevices.removeAll()
        }
    }

    // MARK: - Delete Device Confirmation Actions

    @ViewBuilder
    private var deleteDeviceConfirmationActions: some View {
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
