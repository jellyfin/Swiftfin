//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

enum ProgramType: String, CaseIterable, Displayable, Identifiable, LosslessStringConvertible, Storable {

    case kids
    case movies
    case news
    case series
    case sports

    init?(_ description: String) {
        self.init(rawValue: description)
    }

    var description: String {
        rawValue
    }

    var id: String {
        rawValue
    }

    var displayTitle: String {
        switch self {
        case .kids:
            L10n.kids
        case .movies:
            L10n.movies
        case .news:
            L10n.news
        case .series:
            L10n.series
        case .sports:
            L10n.sports
        }
    }

    var color: Color {
        switch self {
        case .kids:
            .yellow
        case .movies:
            .blue
        case .news:
            .orange
        case .series:
            .purple
        case .sports:
            .green
        }
    }

    func matches(_ program: BaseItemDto) -> Bool {
        switch self {
        case .kids:
            program.isKids == true
        case .movies:
            program.isMovie == true
        case .news:
            program.isNews == true
        case .series:
            program.isSeries == true
        case .sports:
            program.isSports == true
        }
    }
}
