//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum MediaPlaybackStrategy: Hashable, CaseIterable, Displayable, Storable {

    case auto
    case player(VideoPlayerType)

    static var allCases: [MediaPlaybackStrategy] {
        [.auto] + VideoPlayerType.allCases.map(MediaPlaybackStrategy.player)
    }

    var displayTitle: String {
        switch self {
        case .auto:
            L10n.auto
        case let .player(type):
            type.displayTitle
        }
    }

    var forcedPlayer: VideoPlayerType? {
        switch self {
        case .auto:
            nil
        case let .player(type):
            type
        }
    }

    var allowsEngineFallback: Bool {
        switch self {
        case .player(.vlc):
            false
        default:
            true
        }
    }
}

extension MediaPlaybackStrategy: RawRepresentable {

    init?(rawValue: String) {
        if rawValue == "auto" {
            self = .auto
        } else if let type = VideoPlayerType(rawValue: rawValue) {
            self = .player(type)
        } else {
            return nil
        }
    }

    var rawValue: String {
        switch self {
        case .auto:
            "auto"
        case let .player(type):
            type.rawValue
        }
    }
}

extension MediaPlaybackStrategy: Codable {

    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = MediaPlaybackStrategy(rawValue: rawValue) ?? .auto
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
