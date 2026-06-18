//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension BaseItemPerson: LibraryElement {

    static var supportedLibraryStyleOptions: LibraryStyleOptions {
        BaseItemKind.libraryStyleOptions(for: [.person])
    }

    func libraryDidSelectElement(router: Router.Wrapper, in namespace: Namespace.ID) {
        BaseItemDto(person: self)
            .libraryDidSelectElement(router: router, in: namespace)
    }
}
