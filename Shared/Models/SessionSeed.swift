//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Minimal, non-purgeable data needed to rebuild a signed-in session after the CoreData store is lost.
struct SessionSeed: Codable, Hashable {

    enum CodingKeys: String, CodingKey {
        case userID
        case serverID
        case username
        case serverName
        case currentServerURL
        case serverURLs
        case accessPolicyRawValue
        case pinHint
        case updatedAt
    }

    let userID: String
    let serverID: String
    var username: String
    var serverName: String
    var currentServerURL: URL
    var serverURLs: [URL]
    var accessPolicyRawValue: String
    var pinHint: String?
    var updatedAt: Date

    init(
        userID: String,
        serverID: String,
        username: String,
        serverName: String,
        currentServerURL: URL,
        serverURLs: [URL],
        accessPolicyRawValue: String,
        pinHint: String?
    ) {
        self.userID = userID
        self.serverID = serverID
        self.username = username
        self.serverName = serverName
        self.currentServerURL = currentServerURL
        self.serverURLs = serverURLs
        self.accessPolicyRawValue = accessPolicyRawValue
        self.pinHint = pinHint
        self.updatedAt = Date()
    }

    mutating func touch() {
        updatedAt = Date()
    }
}
