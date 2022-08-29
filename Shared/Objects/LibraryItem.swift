//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct LibraryItem: Equatable, Poster {

    var library: BaseItemDto
    var viewModel: MediaViewModel
    var title: String = ""
    var subtitle: String?
    var showTitle: Bool = false

    func portraitPosterImageSource(maxWidth: CGFloat) -> ImageSource {
        .init()
    }

    func landscapePosterImageSources(maxWidth: CGFloat, single: Bool) -> [ImageSource] {
        viewModel.libraryImages[library.id ?? ""] ?? []
    }

    static func == (lhs: LibraryItem, rhs: LibraryItem) -> Bool {
        lhs.library == rhs.library &&
            lhs.viewModel.libraryImages[lhs.library.id ?? ""] == rhs.viewModel.libraryImages[rhs.library.id ?? ""]
    }
}
