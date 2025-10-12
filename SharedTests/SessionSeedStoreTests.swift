//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
@testable import Swiftfin_iOS
import XCTest

final class SessionSeedStoreTests: XCTestCase {

    private var keychain: MockKeychain!
    private var store: SessionSeedStore!

    override func setUp() {
        super.setUp()
        keychain = MockKeychain()
        store = SessionSeedStore(keychain: keychain)
        Defaults[.sessionSeedUserIDs] = []
    }

    override func tearDown() {
        Defaults[.sessionSeedUserIDs] = []
        store = nil
        keychain = nil
        super.tearDown()
    }

    func testUpsertAndRetrieveSeed() throws {
        let seed = SessionSeed(
            userID: "userA",
            serverID: "serverA",
            username: "username",
            serverName: "Server Name",
            currentServerURL: URL(string: "https://example.com")!,
            serverURLs: [URL(string: "https://example.com")!],
            accessPolicyRawValue: UserAccessPolicy.none.rawValue,
            pinHint: nil
        )

        store.upsert(seed: seed)

        guard let retrieved = store.seed(for: seed.userID) else {
            XCTFail("Expected to retrieve stored seed")
            return
        }

        XCTAssertEqual(retrieved.userID, seed.userID)
        XCTAssertEqual(retrieved.serverID, seed.serverID)
        XCTAssertEqual(retrieved.username, seed.username)
        XCTAssertEqual(retrieved.serverName, seed.serverName)
        XCTAssertEqual(retrieved.currentServerURL, seed.currentServerURL)
        XCTAssertEqual(Set(retrieved.serverURLs), Set(seed.serverURLs))
        XCTAssertEqual(retrieved.accessPolicyRawValue, seed.accessPolicyRawValue)
        XCTAssertNil(retrieved.pinHint)
        XCTAssertTrue(retrieved.updatedAt >= seed.updatedAt)
        XCTAssertTrue(Defaults[.sessionSeedUserIDs].contains(seed.userID))
    }

    func testDeleteRemovesSeedAndIndex() {
        let seed = SessionSeed(
            userID: "userB",
            serverID: "serverB",
            username: "other",
            serverName: "Server",
            currentServerURL: URL(string: "https://server.com")!,
            serverURLs: [URL(string: "https://server.com")!],
            accessPolicyRawValue: UserAccessPolicy.requirePin.rawValue,
            pinHint: "1234"
        )

        store.upsert(seed: seed)
        store.delete(userID: seed.userID)

        XCTAssertNil(store.seed(for: seed.userID))
        XCTAssertFalse(Defaults[.sessionSeedUserIDs].contains(seed.userID))
    }

    func testSeedsReturnsAllStoredSeeds() {
        let first = SessionSeed(
            userID: "user1",
            serverID: "server1",
            username: "alpha",
            serverName: "Server 1",
            currentServerURL: URL(string: "https://one.example")!,
            serverURLs: [URL(string: "https://one.example")!],
            accessPolicyRawValue: UserAccessPolicy.none.rawValue,
            pinHint: nil
        )
        let second = SessionSeed(
            userID: "user2",
            serverID: "server2",
            username: "beta",
            serverName: "Server 2",
            currentServerURL: URL(string: "https://two.example")!,
            serverURLs: [URL(string: "https://two.example")!],
            accessPolicyRawValue: UserAccessPolicy.requireDeviceAuthentication.rawValue,
            pinHint: nil
        )

        store.upsert(seed: first)
        store.upsert(seed: second)

        let seeds = store.seeds()
        XCTAssertEqual(seeds.count, 2)
        XCTAssertTrue(seeds.contains(where: { $0.userID == first.userID }))
        XCTAssertTrue(seeds.contains(where: { $0.userID == second.userID }))
    }
}
