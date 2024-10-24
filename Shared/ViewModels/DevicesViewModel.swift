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

final class DevicesViewModel: ViewModel, Eventful, Stateful {

    // MARK: Event

    enum Event {
        case error(JellyfinAPIError)
        case success
    }

    // MARK: - Action

    enum Action: Equatable {
        case getDevices
        case setCustomName(id: String, newName: String)
        case deleteDevices(ids: [String])
    }

    // MARK: - BackgroundState

    enum BackgroundState: Hashable {
        case gettingDevices
        case settingCustomName
        case deletingDevices
    }

    // MARK: - State

    enum State: Hashable {
        case content
        case error(JellyfinAPIError)
        case initial
    }

    // MARK: Published Values

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    @Published
    final var backgroundStates: OrderedSet<BackgroundState> = []
    @Published
    final var devices: OrderedDictionary<String, BindingBox<DeviceInfo?>> = [:]
    @Published
    final var state: State = .initial

    @Published
    private(set) var userID: String?

    private var deviceTask: AnyCancellable?
    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    // MARK: - Initializer

    init(_ userID: String? = nil) {
        self.userID = userID
    }

    // MARK: - Respond to Action

    func respond(to action: Action) -> State {
        switch action {
        case .getDevices:
            deviceTask?.cancel()

            backgroundStates.append(.gettingDevices)

            deviceTask = Task { [weak self] in
                do {
                    try await self?.loadDevices(
                        userID: self?.userID
                    )
                    await MainActor.run {
                        self?.state = .content
                        self?.eventSubject.send(.success)
                    }
                } catch {
                    guard let self else { return }
                    await MainActor.run {
                        let jellyfinError = JellyfinAPIError(error.localizedDescription)
                        self.state = .error(jellyfinError)
                        self.eventSubject.send(.error(jellyfinError))
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

            backgroundStates.append(.settingCustomName)

            deviceTask = Task { [weak self] in
                do {
                    try await self?.setCustomName(id: id, newName: newName)
                    await MainActor.run {
                        self?.state = .content
                        self?.eventSubject.send(.success)
                    }
                } catch {
                    guard let self else { return }
                    await MainActor.run {
                        let jellyfinError = JellyfinAPIError(error.localizedDescription)
                        self.state = .error(jellyfinError)
                        self.eventSubject.send(.error(jellyfinError))
                    }
                }

                await MainActor.run {
                    let _ = self?.backgroundStates.remove(.settingCustomName)
                }
            }
            .asAnyCancellable()

            return state

        case let .deleteDevices(ids):
            deviceTask?.cancel()

            backgroundStates.append(.deletingDevices)

            deviceTask = Task { [weak self] in
                do {
                    try await self?.deleteDevices(ids: ids)
                    await MainActor.run {
                        self?.state = .content
                        self?.eventSubject.send(.success)
                    }
                } catch {
                    await MainActor.run {
                        let jellyfinError = JellyfinAPIError(error.localizedDescription)
                        self?.state = .error(jellyfinError)
                        self?.eventSubject.send(.error(jellyfinError))
                    }
                }

                await MainActor.run {
                    let _ = self?.backgroundStates.remove(.deletingDevices)
                }
            }
            .asAnyCancellable()

            return state
        }
    }

    // MARK: - Load Devices

    private func loadDevices(userID: String?) async throws {
        let request = Paths.getDevices(userID: userID)
        let response = try await userSession.client.send(request)

        guard let devices = response.value.items else {
            return
        }

        await MainActor.run {
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

    // MARK: - Set Custom Name

    private func setCustomName(id: String, newName: String) async throws {
        let request = Paths.updateDeviceOptions(id: id, DeviceOptionsDto(customName: newName))
        try await userSession.client.send(request)

        if let _ = devices[id]?.value {
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
            let _ = self.devices.removeValue(forKey: id)
        }
    }

    // MARK: - Delete Devices

    private func deleteDevices(ids: [String]) async throws {
        guard ids.isNotEmpty else {
            return
        }

        // Don't allow self-deletion
        let deviceIdsToDelete = ids.filter { $0 != userSession.client.configuration.deviceID }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for deviceId in deviceIdsToDelete {
                group.addTask {
                    try await self.deleteDevice(id: deviceId)
                }
            }

            try await group.waitForAll()
        }

        await MainActor.run {
            self.devices = self.devices.filter {
                !deviceIdsToDelete.contains($0.key)
            }
        }
    }
}
