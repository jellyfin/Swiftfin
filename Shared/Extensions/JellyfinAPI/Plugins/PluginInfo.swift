//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension PluginInfo: Displayable {

    var displayTitle: String {
        name ?? L10n.unknown
    }

    var isInstalled: Bool {
        guard let status else { return false }

        switch status {
        case .active, .restart, .disabled, .malfunctioned, .notSupported:
            return true
        case .deleted, .superseded, .superceded:
            return false
        }
    }
}

extension PluginInfo {

    init(package: PackageInfo) {
        self.init(
            description: package.overview,
            id: package.id,
            name: package.name
        )
    }
}
