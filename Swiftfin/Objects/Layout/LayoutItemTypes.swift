//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

enum LayoutItemTypes {

    static let all: [BaseItemKind] = BaseItemKind.supportedCases
        .appending([
            .audio,
            .audioBook,
            .book,
            .episode,
            .folder,
            .liveTvChannel,
            .liveTvProgram,
            .musicAlbum,
            .musicArtist,
            .person,
            .photo,
            .photoAlbum,
            .playlist,
            .program,
            .recording,
            .season,
            .trailer,
            .tvChannel,
            .tvProgram,
        ])
        .uniqued { $0 }
}

extension ItemFilterCollection {

    func resolvingLayoutItemTypes(
        library: LibraryReference?
    ) -> Self {
        guard library == nil, itemTypes.isEmpty else { return self }

        var resolved = self
        resolved.itemTypes = LayoutItemTypes.all
        return resolved
    }
}
