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

    case home
    #if os(tvOS)
    case boxSets
    case tvShows
    case movies
    case settings
    #endif
    case search
    case media
    case none

    var displayTitle: String {
        switch self {
        case .home:
            return L10n.home
        #if os(tvOS)
        case .boxSets:
            return L10n.collections
        case .tvShows:
            return L10n.tvShows
        case .movies:
            return L10n.movies
        case .settings:
            return L10n.settings
        #endif
        case .search:
            return L10n.search
        case .media:
            return L10n.media
        case .none:
            return L10n.none
        }
    }

    var displayIcon: Image {
        switch self {
        case .home:
            return Image(systemName: "house")
        #if os(tvOS)
        case .boxSets:
            return Image(systemName: "folder")
        case .tvShows:
            return Image(systemName: "tv")
                .symbolRenderingMode(.monochrome)
        case .movies:
            return Image(systemName: "film")
        case .settings:
            return Image(systemName: "gearshape.fill")
        #endif
        case .search:
            return Image(systemName: "magnifyingglass")
        case .media:
            return Image(systemName: "rectangle.stack")
        case .none:
            return Image(systemName: "questionmark")
        }
    }

    var keyPath: AnyKeyPath? {
        switch self {
        case .home:
            return \MainTabCoordinator.home
        #if os(tvOS)
        case .boxSets:
            return \MainTabCoordinator.boxSets
        case .tvShows:
            return \MainTabCoordinator.tvShows
        case .movies:
            return \MainTabCoordinator.movies
        case .settings:
            return \MainTabCoordinator.settings
        #endif
        case .search:
            return \MainTabCoordinator.search
        case .media:
            return \MainTabCoordinator.media
        case .none:
            return nil
        }
    }
}
