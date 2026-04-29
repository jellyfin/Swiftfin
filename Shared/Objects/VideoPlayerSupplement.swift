//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum VideoPlayerSupplement: String, CaseIterable, Displayable, Equatable, Identifiable, Storable, SystemImageable, SupportedCaseIterable {

    case info
    case chapters
    case queue
    case playbackInformation
    case people

    var displayTitle: String {
        switch self {
        case .info:
            L10n.info
        case .chapters:
            L10n.chapters
        case .queue:
            L10n.episodes
        case .people:
            L10n.people
        case .playbackInformation:
            L10n.session
        }
    }

    var id: String {
        rawValue
    }

    var systemImage: String {
        switch self {
        case .info:
            "info.circle.fill"
        case .chapters:
            "list.bullet.rectangle.fill"
        case .queue:
            "list.triangle"
        case .people:
            "person.2.fill"
        case .playbackInformation:
            "waveform.circle.fill"
        }
    }

    static let supportedCases: [VideoPlayerSupplement] = [.info, .chapters, .queue]
}
