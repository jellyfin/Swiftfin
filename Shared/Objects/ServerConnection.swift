//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum ServerConnectionInterface: String, CaseIterable, Codable, Displayable, Hashable {
    case any
    case wifi
    case cellular

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .any
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
        }
    }
}

struct ServerConnection: Hashable, Identifiable, Storable {

    enum TestState {
        case idle
        case testing
        case success
        case failure(String)
    }

    var id: String = UUID().uuidString
    var name: String
    var url: URL
    var interface: ServerConnectionInterface
    var wifiSSID: String
    var priority: Int

    init(
        id: String = UUID().uuidString,
        name: String,
        url: URL,
        interface: ServerConnectionInterface,
        wifiSSID: String = .empty,
        priority: Int
    ) {
        self.id = id
        self.name = name
        self.url = url
        #if os(tvOS)
        self.interface = .any
        self.wifiSSID = .empty
        #else
        self.interface = interface
        self.wifiSSID = wifiSSID
        #endif
        self.priority = priority
    }

    var displayName: String {
        name.nilIfBlank ?? url.absoluteString
    }

    var normalizedSSID: String? {
        #if os(iOS)
        wifiSSID.nilIfBlank
        #else
        nil
        #endif
    }

    func matches(_ context: NetworkConnectionContext) -> Bool {
        switch normalizedInterface {
        case .any:
            return context.isSatisfied
        case .wifi:
            guard context.interface == .wifi else { return false }
            guard let normalizedSSID else { return true }
            return normalizedSSID.caseInsensitiveCompare(context.wifiSSID ?? .empty) == .orderedSame
        case .cellular:
            return context.interface == .cellular
        }
    }

    var normalizedInterface: ServerConnectionInterface {
        #if os(tvOS)
        .any
        #else
        interface
        #endif
    }

    var normalizedURL: URL {
        url.normalizedServerConnectionURL ?? url
    }

    static func isDuplicate(_ connection: ServerConnection, in connections: [ServerConnection]) -> Bool {
        connections.contains { existingConnection in
            existingConnection.id != connection.id &&
                existingConnection.normalizedURL == connection.normalizedURL &&
                existingConnection.normalizedInterface == connection.normalizedInterface &&
                existingConnection.normalizedSSID == connection.normalizedSSID
        }
    }

    static func defaults(for server: ServerState) -> [ServerConnection] {
        let urls = [server.currentURL] + server.urls
            .subtracting([server.currentURL])
            .sorted(using: \.absoluteString)

        return urls.enumerated().map { index, url in
            ServerConnection(
                name: url == server.currentURL ? L10n.currentURL : url.absoluteString,
                url: url,
                interface: .any,
                priority: index
            )
        }
    }

    static func normalize(_ connections: [ServerConnection], preservingOrder: Bool = false) -> [ServerConnection] {
        let connections = preservingOrder ? connections : connections.sorted(using: \.priority)

        return connections
            .enumerated()
            .map { index, connection in
                connection.with(priority: index)
            }
    }

    func with(priority: Int) -> ServerConnection {
        var copy = self
        copy.priority = priority
        #if os(tvOS)
        copy.interface = .any
        copy.wifiSSID = .empty
        #endif
        return copy
    }
}

extension URL {

    var normalizedServerConnectionURL: URL? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return nil }

        components.scheme = components.scheme?.lowercased()
        components.host = components.host?.lowercased()

        if components.path.isNotEmpty {
            components.path = components.path.trimmingSuffix("/")
        }

        return components.url
    }
}
