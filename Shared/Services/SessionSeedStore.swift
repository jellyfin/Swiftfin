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
import KeychainSwift
import Logging

protocol KeychainStoring {
    @discardableResult
    func storeData(_ value: Data, for key: String, access: KeychainSwiftAccessOptions?) -> Bool
    func data(for key: String) -> Data?
    func string(for key: String) -> String?
    @discardableResult
    func storeString(_ value: String, for key: String, access: KeychainSwiftAccessOptions?) -> Bool
    @discardableResult
    func delete(_ key: String) -> Bool
}

extension KeychainStoring {
    @discardableResult
    func storeData(_ value: Data, for key: String) -> Bool {
        storeData(value, for: key, access: nil)
    }

    @discardableResult
    func storeString(_ value: String, for key: String) -> Bool {
        storeString(value, for: key, access: nil)
    }
}

extension KeychainSwift: KeychainStoring {

    func storeData(_ value: Data, for key: String, access: KeychainSwiftAccessOptions?) -> Bool {
        set(value, forKey: key, withAccess: access)
    }

    func data(for key: String) -> Data? {
        getData(key)
    }

    func string(for key: String) -> String? {
        get(key)
    }

    func storeString(_ value: String, for key: String, access: KeychainSwiftAccessOptions?) -> Bool {
        set(value, forKey: key, withAccess: access)
    }
}

final class SessionSeedStore {

    private enum Constants {
        static let seedKeyPrefix = "sessionSeed-"
    }

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let keychain: KeychainStoring
    private let logger = Logger.swiftfin()

    init(keychain: KeychainStoring) {
        self.keychain = keychain

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    var hasSeeds: Bool {
        !userIDs.isEmpty
    }

    var userIDs: [String] {
        Defaults[.sessionSeedUserIDs]
    }

    func seed(for userID: String) -> SessionSeed? {
        guard let data = keychain.data(for: key(for: userID)) else { return nil }
        do {
            return try decoder.decode(SessionSeed.self, from: data)
        } catch {
            logger.error("Unable to decode seed for user \(userID): \(error.localizedDescription)")
            return nil
        }
    }

    func seeds() -> [SessionSeed] {
        userIDs.compactMap { seed(for: $0) }
    }

    func upsert(seed: SessionSeed) {
        var seedToStore = seed
        seedToStore.touch()

        do {
            let data = try encoder.encode(seedToStore)
            let stored = keychain.storeData(
                data,
                for: key(for: seedToStore.userID),
                access: .accessibleAfterFirstUnlockThisDeviceOnly
            )

            if stored {
                updateUserIDs(inserting: seedToStore.userID)
            } else {
                logger.error("Failed to store session seed for user \(seedToStore.userID)")
            }
        } catch {
            logger.error("Failed to encode session seed for user \(seed.userID): \(error.localizedDescription)")
        }
    }

    func upsert(user: UserState, server: ServerState) {
        guard let seed = makeSeed(user: user, server: server) else { return }
        upsert(seed: seed)
    }

    func upsertAllUsers(of server: ServerState) {
        for userID in server.userIDs {
            guard let storedUser = try? SwiftfinStore.dataStack.fetchOne(From<UserModel>().where(\.$id == userID)) else {
                continue
            }

            upsert(user: storedUser.state, server: server)
        }
    }

    func delete(userID: String) {
        keychain.delete(key(for: userID))
        updateUserIDs(removing: userID)
    }

    func purgeMissingKeychainEntries() {
        let ids = userIDs
        let filtered = ids.filter { keychain.data(for: key(for: $0)) != nil }
        if filtered.count != ids.count {
            Defaults[.sessionSeedUserIDs] = filtered
        }
    }

    private func key(for userID: String) -> String {
        "\(Constants.seedKeyPrefix)\(userID)"
    }

    private func updateUserIDs(inserting userID: String) {
        var set = Set(Defaults[.sessionSeedUserIDs])
        set.insert(userID)
        Defaults[.sessionSeedUserIDs] = Array(set).sorted()
    }

    private func updateUserIDs(removing userID: String) {
        var set = Set(Defaults[.sessionSeedUserIDs])
        if set.remove(userID) != nil {
            Defaults[.sessionSeedUserIDs] = Array(set).sorted()
        }
    }

    private func makeSeed(user: UserState, server: ServerState) -> SessionSeed? {
        guard let currentURL = userPreferredServerURL(server: server) else {
            logger.error("Unable to determine current server URL when creating seed for user \(user.id)")
            return nil
        }

        let serverURLs = server.urls
            .map(\.absoluteString)
            .sorted()
            .compactMap(URL.init(string:))

        let pinHint = user.pinHint.isEmpty ? nil : user.pinHint

        return SessionSeed(
            userID: user.id,
            serverID: server.id,
            username: user.username,
            serverName: server.name,
            currentServerURL: currentURL,
            serverURLs: serverURLs,
            accessPolicyRawValue: user.accessPolicy.rawValue,
            pinHint: pinHint
        )
    }

    private func userPreferredServerURL(server: ServerState) -> URL? {
        server.urls.first { $0 == server.currentURL } ?? server.currentURL
    }
}

extension Container {

    var sessionSeedStore: Factory<SessionSeedStore> {
        self {
            SessionSeedStore(keychain: self.keychainService())
        }.singleton
    }
}
