//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension PluginDetailsViewModel: @MainActor Poster {

    nonisolated static func == (lhs: PluginDetailsViewModel, rhs: PluginDetailsViewModel) -> Bool {
        lhs === rhs
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    var displayTitle: String {
        plugin.displayTitle
    }

    var preferredPosterDisplayType: PosterDisplayType {
        .landscape
    }

    var systemImage: String {
        "puzzlepiece.extension"
    }

    func imageSources(
        for displayType: PosterDisplayType,
        environment: Empty
    ) -> [ImageSource] {
        if plugin.isInstalled, plugin.hasImage == true, let id = plugin.id, let version = plugin.version {
            ImageSource(url: userSession?.client.url(with: Paths.getPluginImage(pluginID: id, version: version)))
        }

        ImageSource(url: URL(string: package?.imageURL))
    }
}
