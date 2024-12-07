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

    @ObservedObject
    private var viewModel: ServerUserAdminViewModel
    @ObservedObject
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
        self.viewModel = viewModel
        self.tempPolicy = viewModel.user.policy ?? UserPolicy()
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(L10n.stringWithAccess(L10n.device))
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
                viewModel.send(.loadLibraries(isHidden: false))
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
                                deviceImage(device)
                                deviceDetails(device)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Device Details View

    @ViewBuilder
    private func deviceDetails(_ device: DeviceInfo) -> some View {
        VStack(alignment: .leading) {

            // TODO: 10.9 SDK - Enable Nicknames
            Text(device.name ?? L10n.unknown)
                .font(.headline)
                .lineLimit(1)
                .multilineTextAlignment(.leading)

            TextPairView(
                leading: L10n.latestWithString(L10n.user),
                trailing: device.lastUserName ?? L10n.unknown
            )
            .lineLimit(1)

            TextPairView(
                leading: L10n.client,
                trailing: device.appName ?? L10n.unknown
            )
            .lineLimit(1)

            TextPairView(
                L10n.lastSeen,
                value: Text(device.dateLastActivity, format: .lastSeen)
            )
            .id(currentDate)
            .monospacedDigit()
        }
        .font(.subheadline)
        .foregroundStyle(.primary, .secondary)
    }

    // MARK: - Device Image View

    @ViewBuilder
    private func deviceImage(_ device: DeviceInfo) -> some View {
        ZStack {
            device.type.clientColor

            Image(device.type.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40)
        }
        .squarePosterStyle()
        .posterShadow()
        .frame(width: 60, height: 60)
        .padding(.trailing)
    }
}
