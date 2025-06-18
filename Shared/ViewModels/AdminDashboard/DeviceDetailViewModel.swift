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

final class DeviceDetailViewModel: ViewModel, Stateful, Eventful {

    enum Event {
        case error(JellyfinAPIError)
        case setCustomName
    }

    enum Action: Equatable {
        case setCustomName(String)
    }

    enum BackgroundState: Hashable {
        case updating
    }

    enum State: Hashable {
        case initial
    }

    @Published
    var backgroundStates: Set<BackgroundState> = []
    @Published
    var state: State = .initial

    @Published
    private(set) var device: DeviceInfoDto

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    init(device: DeviceInfoDto) {
        self.device = device
    }

    func respond(to action: Action) -> State {
        switch action {
        case let .setCustomName(newName):
            cancellables = []

            Task {
                await MainActor.run {
                    _ = backgroundStates.insert(.updating)
                }

                do {
                    try await setCustomName(newName: newName)

                    await MainActor.run {
                        self.eventSubject.send(.setCustomName)
                    }
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(.init(L10n.unableToUpdateCustomName)))
                    }
                }

                await MainActor.run {
                    _ = backgroundStates.remove(.updating)
                }
            }
            .store(in: &cancellables)

            return .initial
        }
    }

    private func setCustomName(newName: String) async throws {
        guard let id = device.id else { return }

        let request = Paths.updateDeviceOptions(id: id, .init(customName: newName))
        try await userSession.client.send(request)

        await MainActor.run {
            self.device.customName = newName
        }
    }

    private func getDeviceInfo() async throws {
        guard let id = device.id else { return }

        let request = Paths.getDeviceInfo(id: id)
        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.device = response.value
        }
    }
}
