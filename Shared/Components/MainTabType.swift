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

    #if os(tvOS)
    case boxSets
    case movies
    case tvShows
    #endif
    case home
    case media
    case search

    var displayTitle: String {
        switch self {
        #if os(tvOS)
        case .boxSets:
            return L10n.collections
        case .movies:
            return L10n.movies
        case .tvShows:
            return L10n.tvShows
        #endif
        case .home:
            return L10n.home
        case .media:
            return L10n.media
        case .search:
            return L10n.search
        }
    }

    var displayIcon: Image {
        switch self {
        #if os(tvOS)
        case .boxSets:
            return Image(systemName: "folder")
        case .movies:
            return Image(systemName: "film")
        case .tvShows:
            return Image(systemName: "tv")
                .symbolRenderingMode(.monochrome)
        #endif
        case .home:
            return Image(systemName: "house")
        case .media:
            return Image(systemName: "rectangle.stack")
        case .search:
            return Image(systemName: "magnifyingglass")
        }
    }

    var keyPath: AnyKeyPath? {
        switch self {
        #if os(tvOS)
        case .boxSets:
            return \MainTabCoordinator.boxSets
        case .movies:
            return \MainTabCoordinator.movies
        case .tvShows:
            return \MainTabCoordinator.tvShows
        #endif
        case .home:
            return \MainTabCoordinator.home
        case .media:
            return \MainTabCoordinator.media
        case .search:
            return \MainTabCoordinator.search
        }
    }
}
