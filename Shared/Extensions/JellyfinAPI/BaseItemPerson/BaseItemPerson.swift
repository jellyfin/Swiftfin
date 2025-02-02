//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import UIKit

extension BaseItemPerson: Displayable {
    var displayTitle: String {
        name ?? .emptyDash
    }
}

extension BaseItemPerson: LibraryParent {

    var libraryType: BaseItemKind? {
        .person
    }
}

extension BaseItemPerson {

    // Jellyfin will grab all roles the person played in the show which makes the role
    //    text too long. This will grab the first role which:
    //      - assumes that the most important role is the first
    //      - will also grab the last "(<text>)" instance, like "(voice)"
    var firstRole: String? {
        guard let role = self.role else { return nil }
        let split = role.split(separator: "/")
        guard split.count > 1 else { return role }

        guard let firstRole = split.first?.trimmingCharacters(in: CharacterSet(charactersIn: " ")),
              let lastRole = split.last?.trimmingCharacters(in: CharacterSet(charactersIn: " ")) else { return role }

        var final = firstRole

        if let lastOpenIndex = lastRole.lastIndex(of: "("), let lastClosingIndex = lastRole.lastIndex(of: ")") {
            let roleText = lastRole[lastOpenIndex ... lastClosingIndex]
            final.append(" \(roleText)")
        }

        return final
    }

    // Only displayed person types.
    // Will ignore types like "GuestStar"
    enum DisplayedType: String {
        case actor = "Actor"
        case director = "Director"
        case writer = "Writer"
        case producer = "Producer"
    }

    var isDisplayed: Bool {
        guard let type = type else { return false }
        return DisplayedType(rawValue: type) != nil
    }
}
