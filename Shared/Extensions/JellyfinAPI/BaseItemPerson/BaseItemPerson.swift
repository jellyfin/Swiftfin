//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
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

    var isCrew: Bool {
        type == .director || type == .writer || type == .producer
    }

    /// Shows crew jobs, or first role in a multi-role string
    var displayRole: String? {
        guard let role else { return nil }
        guard !isCrew else { return role }

        let split = role.split(separator: "/")
        guard split.count > 1 else { return role }

        guard let firstRole = split.first?.trimmingCharacters(in: String.space),
              let lastRole = split.last?.trimmingCharacters(in: String.space) else { return role }

        var final = firstRole

        if let lastOpenIndex = lastRole.lastIndex(of: "("), let lastClosingIndex = lastRole.lastIndex(of: ")") {
            let roleText = lastRole[lastOpenIndex ... lastClosingIndex]
            final.append(" \(roleText)")
        }

        return final
    }
}
