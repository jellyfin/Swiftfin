//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum ServerConnectionInterface: String, CaseIterable, Codable, Hashable {
    case any
    case wifi
    case cellular
    case other

    static var allCases: [ServerConnectionInterface] {
        [.any, .wifi, .cellular, .other]
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .other
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var displayTitle: String {
        switch self {
        case .any:
            L10n.anyNetwork
        case .wifi:
            L10n.wifi
        case .cellular:
            L10n.cellular
        case .other:
            L10n.other
        }
    }

    var systemImage: String {
        switch self {
        case .any:
            "network"
        case .wifi:
            "wifi"
        case .cellular:
            "antenna.radiowaves.left.and.right"
        case .other:
            "network"
        }
    }
}

struct ServerConnection: Hashable, Identifiable, Storable {

    var id: String = UUID().uuidString
    var name: String
    var url: URL
    var interface: ServerConnectionInterface
    var wifiSSID: String
    var priority: Int
    var isEnabled: Bool

    init(
        id: String = UUID().uuidString,
        name: String,
        url: URL,
        interface: ServerConnectionInterface,
        wifiSSID: String = .empty,
        priority: Int,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.interface = interface
        self.wifiSSID = wifiSSID
        self.priority = priority
        self.isEnabled = isEnabled
    }

    var displayName: String {
        name.nilIfBlank ?? url.absoluteString
    }

    var normalizedSSID: String? {
        wifiSSID.nilIfBlank
    }

    func matches(_ context: NetworkConnectionContext) -> Bool {
        guard isEnabled else { return false }

        switch interface {
        case .any:
            return context.isSatisfied
        case .wifi:
            guard context.interface == .wifi else { return false }
            guard let normalizedSSID else { return true }
            return normalizedSSID.caseInsensitiveCompare(context.wifiSSID ?? .empty) == .orderedSame
        case .cellular:
            return context.interface == .cellular
        case .other:
            return context.isSatisfied
        }
    }

    static func defaults(for server: ServerState) -> [ServerConnection] {
        let sortedURLs = server.urls
            .union([server.currentURL])
            .sorted(using: \.absoluteString)

        return sortedURLs.enumerated().map { index, url in
            ServerConnection(
                name: url == server.currentURL ? L10n.currentURL : url.absoluteString,
                url: url,
                interface: .any,
                priority: url == server.currentURL ? 0 : index + 1
            )
        }
        .sorted(using: \.priority)
        .enumerated()
        .map { index, connection in
            connection.with(priority: index)
        }
    }

    func with(priority: Int) -> ServerConnection {
        var copy = self
        copy.priority = priority
        return copy
    }
}

struct ServerConnectionChange: Hashable {

    enum Reason: String, Hashable {
        case automatic
        case manual
        case deletedActiveConnection
    }

    let server: ServerState
    let previous: ServerConnection?
    let current: ServerConnection
    let reason: Reason
}

extension String {

    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
