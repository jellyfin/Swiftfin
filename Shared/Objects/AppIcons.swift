//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum AppIcon: String, CaseIterable, Displayable, Identifiable {

    case jellyfin
    case red
    case orange
    case yellow
    case green
    case blue

    var id: String {
        rawValue
    }

    var displayTitle: String {
        switch self {
        case .jellyfin:
            L10n.jellyfin
        case .red:
            L10n.red
        case .orange:
            L10n.orange
        case .yellow:
            L10n.yellow
        case .green:
            L10n.green
        case .blue:
            L10n.blue
        }
    }

    init(alternateIconName: String?) {
        self = Self.allCases.first { alternateIconName?.hasSuffix($0.rawValue) == true } ?? .blue
    }

    func alternateIconName(background: AppIconBackground) -> String? {
        self == .blue && background == .dark ? nil : "AppIcon-\(background.rawValue)-\(rawValue)"
    }
}

enum AppIconBackground: String, CaseIterable, Displayable {

    case dark
    case light

    var displayTitle: String {
        switch self {
        case .dark:
            L10n.dark
        case .light:
            L10n.light
        }
    }

    init(alternateIconName: String?) {
        self = alternateIconName?.contains(Self.light.rawValue) == true ? .light : .dark
    }
}
