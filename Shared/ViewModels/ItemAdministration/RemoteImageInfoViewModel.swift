//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// TODO: Good example of a multi-library view model, find way to generalize
//       - variadic generics when available?
//       - be like server activity that just subclasses and then encapsulates multiple libraries?
//       - need way to wait for initial results of all libraries

@MainActor
final class RemoteImageInfoViewModel: ObservableObject {

    var remoteImageLibrary: PagingLibraryViewModel<RemoteImageLibrary>
    let remoteImageProvidersLibrary: PagingLibraryViewModel<RemoteImageProvidersLibrary>

    init(itemID: String, imageType: ImageType) {
        self.remoteImageLibrary = .init(
            library: .init(
                imageType: imageType,
                itemID: itemID
            )
        )
        self.remoteImageProvidersLibrary = .init(
            library: .init(itemID: itemID)
        )
    }

    func refresh() {
        remoteImageLibrary.refresh()
        remoteImageProvidersLibrary.refresh()
    }
}
