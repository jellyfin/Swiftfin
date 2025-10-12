//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Defaults
import Factory
import Foundation
import JellyfinAPI
import Logging
import Pulse

actor SessionRestorationService {

    struct RestorationSummary {
        let restoredUserIDs: [String]
        let failedUserIDs: [String]
    }

    private enum RestorationError: Error {
        case missingAccessToken
        case invalidServerURL
    }

    private let seedStore: SessionSeedStore
    private let keychain: KeychainStoring
    private let logger = Logger.swiftfin()

    init(seedStore: SessionSeedStore, keychain: KeychainStoring) {
        self.seedStore = seedStore
        self.keychain = keychain
    }

    func migrateExistingSeeds() {
        do {
            let storedUsers = try SwiftfinStore.dataStack.fetchAll(From<UserModel>())

            for storedUser in storedUsers {
                guard let storedServer = storedUser.server else { continue }
                let userState = storedUser.state
                let serverState = storedServer.state
                seedStore.upsert(user: userState, server: serverState)
            }
        } catch {
            logger.error("Failed migrating existing session seeds: \(error.localizedDescription)")
        }

        seedStore.purgeMissingKeychainEntries()
    }

    func needsRestoration() -> Bool {
        do {
            let userCount = try SwiftfinStore.dataStack.fetchCount(From<UserModel>())
            return userCount == 0 && seedStore.hasSeeds
        } catch {
            logger.error("Unable to inspect CoreStore for restoration need: \(error.localizedDescription)")
            return false
        }
    }

    func restoreSessions() async -> RestorationSummary {
        let seeds = seedStore.seeds()
        guard !seeds.isEmpty else {
            return RestorationSummary(restoredUserIDs: [], failedUserIDs: [])
        }

        var restored: [String] = []
        var failed: [String] = []

        for seed in seeds {
            do {
                try await restore(seed: seed)
                restored.append(seed.userID)
            } catch {
                failed.append(seed.userID)
                handleRestorationFailure(for: seed, error: error)
            }
        }

        return RestorationSummary(restoredUserIDs: restored, failedUserIDs: failed)
    }

    private func restore(seed: SessionSeed) async throws {
        guard let accessToken = keychain.string(for: accessTokenKey(for: seed.userID)) else {
            throw RestorationError.missingAccessToken
        }

        let currentURL = seed.currentServerURL

        let client = JellyfinClient(
            configuration: .swiftfinConfiguration(
                url: currentURL,
                accessToken: accessToken
            ),
            sessionConfiguration: .swiftfin,
            sessionDelegate: URLSessionProxyDelegate(logger: NetworkLogger.swiftfin())
        )

        async let userResponse = client.send(Paths.getCurrentUser)
        async let systemResponse = client.send(Paths.getPublicSystemInfo)

        let (userResult, systemResult) = try await (userResponse, systemResponse)

        let userData = userResult.value
        let publicInfo = systemResult.value

        try SwiftfinStore.dataStack.perform { transaction in
            let server = try transaction.fetchOne(From<ServerModel>().where(\.$id == seed.serverID))
                ?? transaction.create(Into<ServerModel>())

            server.id = seed.serverID
            server.name = publicInfo.serverName ?? seed.serverName
            server.currentURL = currentURL
            server.urls = Set(seed.serverURLs).union([currentURL])

            let storedUser = try transaction.fetchOne(From<UserModel>().where(\.$id == seed.userID))
                ?? transaction.create(Into<UserModel>())

            storedUser.id = seed.userID
            storedUser.username = userData.name ?? seed.username
            storedUser.server = server
        }

        guard let storedUser = try SwiftfinStore.dataStack.fetchOne(From<UserModel>().where(\.$id == seed.userID)),
              let storedServer = storedUser.server
        else {
            throw JellyfinAPIError("Unable to fetch restored user or server from CoreStore")
        }

        let userState = storedUser.state
        let serverState = storedServer.state

        userState.accessToken = accessToken
        userState.data = userData

        if let policy = UserAccessPolicy(rawValue: seed.accessPolicyRawValue) {
            userState.accessPolicy = policy
        } else {
            userState.accessPolicy = .none
        }

        if let pinHint = seed.pinHint {
            userState.pinHint = pinHint
        }

        StoredValues[.Server.publicInfo(id: serverState.id)] = publicInfo

        seedStore.upsert(user: userState, server: serverState)
    }

    private func handleRestorationFailure(for seed: SessionSeed, error: Error) {
        logger.error("Failed restoring session for user \(seed.userID): \(error.localizedDescription)")
        seedStore.delete(userID: seed.userID)

        keychain.delete(accessTokenKey(for: seed.userID))
        keychain.delete(pinKey(for: seed.userID))

        if case let .signedIn(userID) = Defaults[.lastSignedInUserID],
           userID == seed.userID
        {
            Defaults[.lastSignedInUserID] = .signedOut
        }
    }

    private func accessTokenKey(for userID: String) -> String {
        "\(userID)-accessToken"
    }

    private func pinKey(for userID: String) -> String {
        "\(userID)-pin"
    }
}

extension Container {

    var sessionRestorationService: Factory<SessionRestorationService> {
        self {
            SessionRestorationService(
                seedStore: self.sessionSeedStore(),
                keychain: self.keychainService()
            )
        }.singleton
    }
}
