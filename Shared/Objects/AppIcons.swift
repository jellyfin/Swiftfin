//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum AppIcon: String, CaseIterable, Displayable, Identifiable {

    case jellyfin
    case red
    case orange
    case yellow
    case green
    case blue

    #if os(tvOS)
    private static let prefix = "AppIcon-tvOS-"
    #else
    private static let prefix = "AppIcon-dark-"
    #endif

    var iconName: String {
        Self.prefix + rawValue
    }

    var id: String {
        iconName
    }

    var alternateIconName: String? {
        self == .blue ? nil : iconName
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

    static func resolve(alternateIconName: String?) -> Self {
        guard let alternateIconName,
              alternateIconName.hasPrefix(prefix)
        else {
            return .blue
        }

        let rawValue = alternateIconName.dropFirst(prefix.count)
        return Self(rawValue: String(rawValue)) ?? .blue
    }
}
