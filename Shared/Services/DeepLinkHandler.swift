//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import Foundation
import JellyfinAPI
import KeychainSwift

extension Container {
    var deepLinkHandler: Factory<DeepLinkHandler> {
        self { DeepLinkHandler() }
            .singleton
    }
}

@MainActor
final class DeepLinkHandler: ObservableObject {

    struct DeepLink: Equatable {

        enum Destination: Equatable {
            case item(id: String)

            // TODO: able to launch library by ID without item pre-retrieval?
//            case library(id: String)
        }

        let serverID: String
        let userID: String
        let destination: Destination

        init?(_ url: URL) {
            guard let match = url.absoluteString.wholeMatch(
                of: /^swiftfin:\/\/(?<serverID>[A-Za-z0-9]+)\/(?<userID>[A-Za-z0-9]+)\/(?<destinationType>item|library)\/(?<destinationID>[A-Za-z0-9]+)\/?$/
            ) else { return nil }

            self.serverID = String(match.output.serverID)
            self.userID = String(match.output.userID)

            self.destination = .item(id: String(match.output.destinationID))
        }
    }

    enum DeepLinkError: Error {
        case missingAuthenticationAction
        case missingServer(String)
        case missingUser(String)
        case wrongCurrentSession
    }

    @Injected(\.keychainService)
    private var keychain: KeychainSwift

    @Published
    var pendingDeepLink: DeepLink?

    nonisolated init() {}

    func consumePendingDeepLink() -> DeepLink? {
        defer {
            pendingDeepLink = nil
        }

        return pendingDeepLink
    }

    func route(for deepLink: DeepLink, using session: UserSession) async throws -> NavigationRoute {
        guard session.server.id == deepLink.serverID, session.user.id == deepLink.userID else {
            throw DeepLinkError.wrongCurrentSession
        }

        switch deepLink.destination {
        case let .item(id):
            return .item(id: id)
//        case let .library(id):
//            let library = try await getItem(id: id, userSession: session)
//            return .library(viewModel: ItemLibraryViewModel(parent: library))
        }
    }

    func sessionTarget(for deepLink: DeepLink) throws -> (server: ServerState, user: UserState) {
        guard let server = StoredValues[.Server.servers].first(where: { $0.id == deepLink.serverID }) else {
            throw DeepLinkError.missingServer(deepLink.serverID)
        }

        guard let user = StoredValues[.User.users].first(where: { $0.id == deepLink.userID && $0.serverID == server.id }) else {
            throw DeepLinkError.missingUser(deepLink.userID)
        }

        return (server, user)
    }

    func authenticate(
        user: UserState,
        authenticationAction: LocalUserAuthenticationAction?
    ) async throws {
        guard user.accessPolicy != .none else { return }

        guard let authenticationAction else {
            throw DeepLinkError.missingAuthenticationAction
        }

        let evaluatedPolicy = try await authenticationAction(
            policy: user.accessPolicy,
            reason: user.accessPolicy.authenticateReason(user: user)
        )

        guard let pinPolicy = evaluatedPolicy as? PinEvaluatedUserAccessPolicy else { return }

        if let storedPin = keychain.get("\(user.id)-pin") {
            guard pinPolicy.pin == storedPin else {
                throw ErrorMessage(L10n.incorrectPinForUser(user.username))
            }
        }
    }
}
