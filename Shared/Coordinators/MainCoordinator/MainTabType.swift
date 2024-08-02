//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import Stinsen
import SwiftUI

enum MainTabTypes: String, CaseIterable, Defaults.Serializable, Displayable {

    case boxSets
    case home
    case media
    case movies
    case search
    case tvShows

    var displayTitle: String {
        switch self {
        case .boxSets:
            return L10n.collections
        case .home:
            return L10n.home
        case .media:
            return L10n.media
        case .movies:
            return L10n.movies
        case .search:
            return L10n.search
        case .tvShows:
            return L10n.tvShows
        }
    }

    var displayIcon: Image {
        switch self {
        case .boxSets:
            return Image(systemName: "folder")
        case .home:
            return Image(systemName: "house")
        case .media:
            return Image(systemName: "rectangle.stack")
        case .movies:
            return Image(systemName: "film")
        case .search:
            return Image(systemName: "magnifyingglass")
        case .tvShows:
            return Image(systemName: "tv")
                .symbolRenderingMode(.monochrome)
        }
    }

    var keyPath: AnyKeyPath? {
        switch self {
        case .boxSets:
            return \MainTabCoordinator.boxSets
        case .home:
            return \MainTabCoordinator.home
        case .media:
            return \MainTabCoordinator.media
        case .movies:
            return \MainTabCoordinator.movies
        case .search:
            return \MainTabCoordinator.search
        case .tvShows:
            return \MainTabCoordinator.tvShows
        }
    }
}
