//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum RemotePlaybackRoute: Hashable, Identifiable, CaseIterable, SupportedCaseIterable, Displayable, SystemImageable {

    case airPlay
    case chromecast
    case jellyfin

    var id: Self {
        self
    }

    var systemImage: String {
        switch self {
        case .airPlay:
            "airplayvideo"
        case .chromecast:
            "rectangle.connected.to.line.below"
        case .jellyfin:
            "tv.badge.wifi"
        }
    }

    var displayTitle: String {
        switch self {
        case .airPlay:
            L10n.airPlay
        case .chromecast:
            L10n.chromecast
        case .jellyfin:
            L10n.jellyfin
        }
    }

    /// `RemotePlaybackType` supported by Swiftfin
    static var supportedCases: [RemotePlaybackRoute] = [.airPlay, .jellyfin]
}
