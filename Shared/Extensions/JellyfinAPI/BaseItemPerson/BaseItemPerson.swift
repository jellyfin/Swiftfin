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

    // Jellyfin will grab all roles the person played in the show which makes the role
    //    text too long. This will grab the first role which:
    //      - assumes that the most important role is the first
    //      - will also grab the last "(<text>)" instance, like "(voice)"
    var firstRole: String? {
        guard let role = self.role else { return nil }
        let split = role.split(separator: "/")
        guard split.count > 1 else { return role }

        guard let firstRole = split.first?.trimmingCharacters(in: CharacterSet(charactersIn: .space)),
              let lastRole = split.last?.trimmingCharacters(in: CharacterSet(charactersIn: .space)) else { return role }

        var final = firstRole

        if let lastOpenIndex = lastRole.lastIndex(of: "("), let lastClosingIndex = lastRole.lastIndex(of: ")") {
            let roleText = lastRole[lastOpenIndex ... lastClosingIndex]
            final.append(" \(roleText)")
        }

        return final
    }
}

/// The person kinds the server sends one credit per job for, meaning someone credited for
/// multiple jobs is sent as multiple people.
let mergeableCrewKinds: Set<PersonKind> = [.director, .writer, .producer]

extension Collection where Element == BaseItemPerson {

    /// Combines the credits of a person holding multiple crew jobs into a single element listing
    /// all of their roles, like "Director / Producer". Kinds outside `mergeableCrewKinds` are never
    /// combined, so an actor playing multiple characters keeps one element per character. The
    /// combined element keeps the position of the first credit.
    func mergingCrewRoles() -> [BaseItemPerson] {
        var people: [BaseItemPerson] = []
        var indices: [String: Int] = [:]

        for person in self {
            guard let type = person.type,
                  mergeableCrewKinds.contains(type),
                  let id = person.id
            else {
                people.append(person)
                continue
            }

            guard let index = indices[id] else {
                indices[id] = people.count
                people.append(person)
                continue
            }

            people[index].role = mergedRole(people[index].role, person.role)
        }

        return people
    }
}

/// Joins two roles, keeping each role listed once.
private func mergedRole(_ role: String?, _ other: String?) -> String? {
    let roles = [role, other]
        .compactMap { $0 }
        .filter { $0.isNotEmpty }
        .reduce(into: [String]()) { unique, next in
            guard !unique.contains(next) else { return }
            unique.append(next)
        }

    return roles.isEmpty ? nil : roles.joined(separator: " / ")
}
