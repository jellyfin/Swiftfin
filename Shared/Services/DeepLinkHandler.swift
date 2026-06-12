//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import JellyfinAPI
import KeychainSwift
import Logging

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
            case library(id: String)
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

            self.destination = String(match.output.destinationType) == "item" ?
                .item(id: String(match.output.destinationID)) :
                .library(id: String(match.output.destinationID))
        }
    }

    enum DeepLinkError: Error {
        case invalidURL
        case missingAuthenticationAction
        case missingCurrentSession
        case missingServer(String)
        case missingUser(String)
        case wrongCurrentSession

        var localizedDescription: String {
            switch self {
            case .invalidURL:
                "The URL is not a supported Swiftfin deep link."
            case .missingAuthenticationAction:
                "Local authentication is unavailable."
            case .missingCurrentSession:
                "No signed-in user session is available."
            case let .missingServer(serverID):
                "No saved server exists for deep link server ID \(serverID)."
            case let .missingUser(userID):
                "No saved user exists for deep link user ID \(userID)."
            case .wrongCurrentSession:
                "The active user session does not match the deep link."
            }
        }
    }

    @Injected(\.keychainService)
    private var keychain: KeychainSwift

    @Published
    private(set) var pendingDeepLink: DeepLink?

    private let logger = Logger.swiftfin()

    nonisolated init() {}

    @discardableResult
    func handle(
        _ url: URL,
        authenticationAction: LocalUserAuthenticationAction?
    ) async -> Bool {
        guard let deepLink = DeepLink(url) else {
            return false
        }

        do {
            try await prepareSession(for: deepLink, authenticationAction: authenticationAction)
            pendingDeepLink = deepLink
            return true
        } catch is CancellationError {
            return true
        } catch {
            logger.error(
                "Failed to process deep link",
                metadata: [
                    "url": .string(url.absoluteString),
                    "error": .stringConvertible(error.localizedDescription),
                ]
            )
            return true
        }
    }

    func consumePendingDeepLink() -> DeepLink? {
        defer {
            pendingDeepLink = nil
        }

        return pendingDeepLink
    }

    func route(for deepLink: DeepLink) async throws -> NavigationRoute {
        guard let session = Container.shared.userSessionManager().currentSession else {
            throw DeepLinkError.missingCurrentSession
        }

        guard session.server.id == deepLink.serverID, session.user.id == deepLink.userID else {
            throw DeepLinkError.wrongCurrentSession
        }

        switch deepLink.destination {
        case let .item(id):
            let item = try await getItem(id: id, userSession: session)
            return .item(item: item)
        case let .library(id):
            let library = try await getItem(id: id, userSession: session)
            return .library(viewModel: ItemLibraryViewModel(parent: library))
        }
    }

    private func prepareSession(
        for deepLink: DeepLink,
        authenticationAction: LocalUserAuthenticationAction?
    ) async throws {
        guard let server = StoredValues[.Server.servers].first(where: { $0.id == deepLink.serverID }) else {
            throw DeepLinkError.missingServer(deepLink.serverID)
        }

        guard let user = StoredValues[.User.users].first(where: { $0.id == deepLink.userID && $0.serverID == server.id }) else {
            throw DeepLinkError.missingUser(deepLink.userID)
        }

        let sessionManager = Container.shared.userSessionManager()
        let currentSession = sessionManager.currentSession
        let isSameUserSession = currentSession?.server.id == server.id && currentSession?.user.id == user.id

        guard !isSameUserSession else {
            return
        }

        try await authenticate(user: user, authenticationAction: authenticationAction)

        if sessionManager.hasActivePlayback {
            await sessionManager.stopActivePlayback()
        }

        if currentSession != nil {
            sessionManager.signOut(reason: .deepLinkUserSwitch)
        }

        sessionManager.signIn(userID: user.id)
    }

    private func authenticate(
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

    private func getItem(id: String, userSession: UserSession) async throws -> BaseItemDto {
        let request = Paths.getItem(itemID: id, userID: userSession.user.id)
        let response = try await userSession.client.send(request)
        return response.value
    }
}
