//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemEntry: @MainActor LibraryElement {

    var supportedLibraryStyleOptions: LibraryStyleOptions {
        snapshot.supportedLibraryStyleOptions
    }

    func libraryDidSelectElement(router: Router.Wrapper, in namespace: Namespace.ID) {
        guard let value else { return }

        value.libraryDidSelectElement(router: router, in: namespace)
    }

    @ViewBuilder
    func makeBody(libraryStyle: LibraryStyle, action: (() -> Void)?) -> some View {
        if let value {
            value.makeBody(libraryStyle: libraryStyle, action: action)
        }
    }
}
