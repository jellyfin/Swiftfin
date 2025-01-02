//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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
        case refresh
        case delete(ids: [String])
    }

    // MARK: - BackgroundState

    enum BackgroundState: Hashable {
        case refreshing
        case updating
        case deleting
    }

    // MARK: - State

    enum State: Hashable {
        case initial
        case content
        case error(JellyfinAPIError)
    }

    // MARK: Published Values

    @Published
    final var backgroundStates: OrderedSet<BackgroundState> = []
    @Published
    final var devices: [DeviceInfo] = []
    @Published
    final var state: State = .initial

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private var deviceTask: AnyCancellable?
    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    // MARK: - Respond to Action

    func respond(to action: Action) -> State {
        switch action {
        case .refresh:
            deviceTask?.cancel()

            backgroundStates.append(.refreshing)

            deviceTask = Task { [weak self] in
                do {
                    try await self?.loadDevices()

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
                    _ = self?.backgroundStates.remove(.refreshing)
                }
            }
            .asAnyCancellable()

            return state
        case let .delete(ids):
            deviceTask?.cancel()

            backgroundStates.append(.deleting)

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
                    _ = self?.backgroundStates.remove(.deleting)
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

        guard let devices = response.value.items else {
            return
        }

        await MainActor.run {
            self.devices = devices.sorted(using: \.dateLastActivity)
                .reversed()
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

        try await loadDevices()
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

        try await loadDevices()
    }
}
