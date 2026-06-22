//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum ServerConnectionInterface: String, CaseIterable, Displayable, Hashable, Storable {
    case any
    case wifi
    case cellular

    var displayTitle: String {
        switch self {
        case .any:
            L10n.any
        case .wifi:
            L10n.wifi
        case .cellular:
            L10n.cellular
        }
    }
}

struct ServerConnection: Displayable, Hashable, Identifiable, Storable {

    enum TestState {
        case idle
        case testing
        case success
        case failure(String)
    }

    let id: String
    var name: String
    private(set) var url: URL
    private(set) var interface: ServerConnectionInterface
    private(set) var wifiSSIDs: [String]
    var priority: Int

    init(
        id: String,
        name: String,
        url: URL,
        interface: ServerConnectionInterface,
        wifiSSIDs: [String] = [],
        priority: Int
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.interface = interface
        self.wifiSSIDs = wifiSSIDs
        self.priority = priority
    }

    var displayTitle: String {
        name.nilIfBlank ?? url.absoluteString
    }

    func matches(_ context: NetworkConnectionContext) -> Bool {
        switch interface {
        case .any:
            return context.isSatisfied
        case .wifi:
            guard context.interface == .wifi else { return false }
            guard wifiSSIDs.isNotEmpty else { return true }
            return wifiSSIDs.contains {
                $0.caseInsensitiveCompare(context.wifiSSID ?? .empty) == .orderedSame
            }
        case .cellular:
            return context.interface == .cellular
        }
    }

    private var ssidKey: Set<String> {
        Set(wifiSSIDs.map(\.localizedLowercase))
    }

    static func isDuplicate(_ connection: ServerConnection, in connections: [ServerConnection]) -> Bool {
        connections.contains { existingConnection in
            existingConnection.id != connection.id &&
                existingConnection.url == connection.url &&
                existingConnection.interface == connection.interface &&
                existingConnection.ssidKey == connection.ssidKey
        }
    }

    static func ordered(_ connections: [ServerConnection], preservingOrder: Bool = false) -> [ServerConnection] {
        let connections = preservingOrder ? connections : connections.sorted(using: \.priority)

        return connections
            .enumerated()
            .map { index, connection in
                connection.with(priority: index)
            }
    }

    func with(priority: Int) -> ServerConnection {
        ServerConnection(
            id: id,
            name: name,
            url: url,
            interface: interface,
            wifiSSIDs: wifiSSIDs,
            priority: priority
        )
    }
}
