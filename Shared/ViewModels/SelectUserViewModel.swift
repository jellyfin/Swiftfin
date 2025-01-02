//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import CoreStore
import Factory
import Foundation
import JellyfinAPI
import KeychainSwift
import OrderedCollections

class SelectUserViewModel: ViewModel, Eventful, Stateful {

    // MARK: Event

    enum Event {
        case error(JellyfinAPIError)
        case signedIn(UserState)
    }

    // MARK: Action

    enum Action: Equatable {
        case deleteUsers([UserState])
        case getServers
        case signIn(UserState, pin: String)
    }

    // MARK: State

    enum State: Hashable {
        case content
    }

    @Published
    var servers: OrderedDictionary<ServerState, [UserState]> = [:]
    @Published
    var state: State = .content

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .eraseToAnyPublisher()
    }

    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    @MainActor
    func respond(to action: Action) -> State {
        switch action {
        case let .deleteUsers(users):
            do {
                for user in users {
                    try delete(user: user)
                }

                send(.getServers)
            } catch {
                eventSubject.send(.error(.init(error.localizedDescription)))
            }
        case .getServers:
            do {
                servers = try getServers()
                    .zipped(map: getUsers)
                    .reduce(into: OrderedDictionary<ServerState, [UserState]>()) { partialResult, pair in
                        partialResult[pair.0] = pair.1
                    }

                return .content
            } catch {
                eventSubject.send(.error(.init(error.localizedDescription)))
            }
        case let .signIn(user, pin):

            if user.accessPolicy == .requirePin, let storedPin = keychain.get("\(user.id)-pin") {
                if pin != storedPin {
                    eventSubject.send(.error(.init("Incorrect pin for \(user.username)")))

                    return .content
                }
            }

            eventSubject.send(.signedIn(user))
        }

        return .content
    }

    private func getServers() throws -> [ServerState] {
        try SwiftfinStore
            .dataStack
            .fetchAll(From<ServerModel>())
            .map(\.state)
            .sorted(using: \.name)
    }

    private func getUsers(for server: ServerState) throws -> [UserState] {
        guard let storedServer = try? dataStack.fetchOne(From<ServerModel>().where(\.$id == server.id)) else {
            throw JellyfinAPIError("Unable to find server for users")
        }

        return storedServer.users
            .map(\.state)
    }

    private func delete(user: UserState) throws {
        try user.delete()
    }
}
