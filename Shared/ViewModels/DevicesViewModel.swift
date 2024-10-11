//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections
import SwiftUI

final class DevicesViewModel: ViewModel, Stateful {

    // MARK: - Action

    enum Action: Equatable {
        case getDevices
        case setCustomName(id: String, newName: String)
        case deleteDevice(id: String)
        case deleteAllDevices
    }

    // MARK: - BackgroundState

    enum BackgroundState: Hashable {
        case gettingDevices
        case settingCustomName
        case deletingDevice
        case deletingAllDevices
    }

    // MARK: - State

    enum State: Hashable {
        case content
        case error(JellyfinAPIError)
        case initial
    }

    @Published
    final var backgroundStates: OrderedSet<BackgroundState> = []
    @Published
    final var devices: OrderedDictionary<String, BindingBox<DeviceInfo?>> = [:]
    @Published
    final var state: State = .initial

    private var deviceTask: AnyCancellable?

    // MARK: - Respond to Action

    func respond(to action: Action) -> State {
        switch action {
        case .getDevices:
            deviceTask?.cancel()

            deviceTask = Task { [weak self] in
                await MainActor.run {
                    let _ = self?.backgroundStates.append(.gettingDevices)
                }

                do {
                    try await self?.loadDevices()
                    await MainActor.run {
                        self?.state = .content
                    }
                } catch {
                    guard let self else { return }
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }

                await MainActor.run {
                    let _ = self?.backgroundStates.remove(.gettingDevices)
                }
            }
            .asAnyCancellable()

            return state

        case let .setCustomName(id, newName):
            deviceTask?.cancel()

            deviceTask = Task { [weak self] in
                await MainActor.run {
                    let _ = self?.backgroundStates.append(.settingCustomName)
                }

                do {
                    try await self?.setCustomName(id: id, newName: newName)
                    await MainActor.run {
                        self?.state = .content
                    }
                } catch {
                    guard let self else { return }
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }

                await MainActor.run {
                    let _ = self?.backgroundStates.remove(.settingCustomName)
                }
            }
            .asAnyCancellable()

            return state

        case let .deleteDevice(id):
            deviceTask?.cancel()

            deviceTask = Task { [weak self] in
                await MainActor.run {
                    let _ = self?.backgroundStates.append(.deletingDevice)
                }

                do {
                    try await self?.deleteDevice(id: id)
                    await MainActor.run {
                        self?.state = .content
                    }
                } catch {
                    guard let self else { return }
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }

                await MainActor.run {
                    let _ = self?.backgroundStates.remove(.deletingDevice)
                }
            }
            .asAnyCancellable()

            return state

        case .deleteAllDevices:
            deviceTask?.cancel()

            deviceTask = Task { [weak self] in
                await MainActor.run {
                    let _ = self?.backgroundStates.append(.deletingAllDevices)
                }

                do {
                    try await self?.deleteAllDevices()
                    await MainActor.run {
                        self?.state = .content
                    }
                } catch {
                    guard let self else { return }
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }

                await MainActor.run {
                    let _ = self?.backgroundStates.remove(.deletingAllDevices)
                }
            }
            .asAnyCancellable()

            return state
        }
    }

    // MARK: - Load Devices

    private func loadDevices() async throws {
        let request = Paths.getDevices()
        let response = try await userSession.client.send(request)

        await MainActor.run {
            if let devices = response.value.items {
                for device in devices {
                    guard let id = device.id else { continue }

                    if let existingDevice = self.devices[id] {
                        existingDevice.value = device
                    } else {
                        self.devices[id] = BindingBox<DeviceInfo?>(
                            source: .init(get: { device }, set: { _ in })
                        )
                    }
                }

                self.devices.sort { x, y in
                    let device0 = x.value.value
                    let device1 = y.value.value
                    return (device0?.dateLastActivity ?? Date()) > (device1?.dateLastActivity ?? Date())
                }
            }
        }
    }

    // MARK: - Set Custom Name

    private func setCustomName(id: String, newName: String) async throws {
        let request = Paths.updateDeviceOptions(id: id, DeviceOptionsDto(customName: newName))
        try await userSession.client.send(request)

        if let device = self.devices[id]?.value {
            await MainActor.run {
                self.devices[id]?.value?.name = newName
            }
        }
    }

    // MARK: - Delete Device

    private func deleteDevice(id: String) async throws {
        // Don't allow self-deletion
        guard id != userSession.client.configuration.deviceID else {
            return
        }

        let request = Paths.deleteDevice(id: id)
        try await userSession.client.send(request)

        await MainActor.run {
            self.devices.removeValue(forKey: id)
        }
    }

    // MARK: - Delete All Devices

    private func deleteAllDevices() async throws {
        let deviceIdsToDelete = self.devices.keys.filter { $0 != userSession.client.configuration.deviceID }

        for deviceId in deviceIdsToDelete {
            print("Deleting: \(deviceId)")
            // try await deleteDevice(id: deviceId)
        }

        await MainActor.run {
            self.devices = self.devices.filter { $0.key == userSession.client.configuration.deviceID }
        }
    }
}
