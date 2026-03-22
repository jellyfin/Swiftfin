//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct TopShelfDeepLink: Equatable, Hashable {

    enum Action: String, Codable, Hashable {
        case display
        case play
    }

    private static let infoKey = "TopShelfURLScheme"
    static var scheme: String {
        guard let scheme = Bundle.main.object(forInfoDictionaryKey: infoKey) as? String,
              !scheme.isEmpty
        else { return "swiftfin-top-shelf" }

        return scheme
    }

    private static let itemHost = "item"

    let action: Action
    let itemID: String
    let userID: String

    init?(
        url: URL
    ) {
        guard url.scheme == Self.scheme,
              url.host == Self.itemHost
        else { return nil }

        let pathComponents = url.pathComponents.filter { $0 != "/" }

        guard let itemID = pathComponents.first,
              !itemID.isEmpty,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let actionValue = components.queryItems?.first(where: { $0.name == "action" })?.value,
              let action = Action(rawValue: actionValue),
              let userID = components.queryItems?.first(where: { $0.name == "userID" })?.value,
              !userID.isEmpty
        else { return nil }

        self.action = action
        self.itemID = itemID
        self.userID = userID
    }

    init(
        action: Action,
        itemID: String,
        userID: String
    ) {
        self.action = action
        self.itemID = itemID
        self.userID = userID
    }

    var url: URL {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = Self.itemHost
        components.path = "/\(itemID)"
        components.queryItems = [
            .init(name: "action", value: action.rawValue),
            .init(name: "userID", value: userID),
        ]

        return components.url!
    }
}
