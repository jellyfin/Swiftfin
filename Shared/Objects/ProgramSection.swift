//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum ProgramSection: String, CaseIterable, Displayable {

    case kids
    case movies
    case news
    case series
    case sports

    var displayTitle: String {
        switch self {
        case .kids:
            return L10n.kids
        case .movies:
            return L10n.movies
        case .news:
            return L10n.news
        case .series:
            return L10n.series
        case .sports:
            return L10n.sports
        }
    }
}
