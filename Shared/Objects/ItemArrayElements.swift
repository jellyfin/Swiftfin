//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

enum ItemArrayElements: Displayable {
    case studios
    case genres
    case tags
    case people

    // MARK: - Localized Title

    var displayTitle: String {
        switch self {
        case .studios:
            return L10n.studios
        case .genres:
            return L10n.genres
        case .tags:
            return L10n.tags
        case .people:
            return L10n.people
        }
    }

    // MARK: - Localized Description

    var description: String {
        switch self {
        case .studios:
            return L10n.studiosDescription
        case .genres:
            return L10n.genresDescription
        case .tags:
            return L10n.tagsDescription
        case .people:
            return L10n.peopleDescription
        }
    }

    // MARK: - Create Element from Components

    func createElement<T: Hashable>(
        name: String,
        id: String?,
        personRole: String?,
        personKind: PersonKind?
    ) -> T {
        switch self {
        case .genres, .tags:
            return name as! T
        case .studios:
            return NameGuidPair(id: id, name: name) as! T
        case .people:
            return BaseItemPerson(
                id: id,
                name: name,
                role: personRole,
                type: personKind
            ) as! T
        }
    }

    // MARK: - Get the Element from the BaseItemDto Based on Type

    func getElement<T: Hashable>(for item: BaseItemDto) -> [T] {
        switch self {
        case .studios:
            return item.studios as? [T] ?? []
        case .genres:
            return item.genres as? [T] ?? []
        case .tags:
            return item.tags as? [T] ?? []
        case .people:
            return item.people as? [T] ?? []
        }
    }

    // MARK: - Get the Name from the Element Based on Type

    func getId(for element: AnyHashable) -> String? {
        switch self {
        case .genres, .tags:
            return nil
        case .studios:
            return (element.base as? NameGuidPair)?.id
        case .people:
            return (element.base as? BaseItemPerson)?.id
        }
    }

    // MARK: - Get the Id from the Element Based on Type

    func getName(for element: AnyHashable) -> String {
        switch self {
        case .genres, .tags:
            return element.base as? String ?? L10n.unknown
        case .studios:
            return (element.base as? NameGuidPair)?.name ?? L10n.unknown
        case .people:
            return (element.base as? BaseItemPerson)?.name ?? L10n.unknown
        }
    }
}
