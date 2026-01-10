//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct ItemStudio: Codable, Hashable, ItemFilter {

    let displayTitle: String
    let value: String

    init(displayTitle: String, value: String) {
        self.displayTitle = displayTitle
        self.value = value
    }

    init(from anyFilter: AnyItemFilter) {
        self.displayTitle = anyFilter.displayTitle
        self.value = anyFilter.value
    }
}

import SwiftUI

extension ItemStudio: LibraryElement {

    func libraryDidSelectElement(router: Router.Wrapper, in namespace: Namespace.ID) {
//        router.route(
//            to: .library(
//                library: Pagingitemlibrar
//            ),
//            in: <#T##Namespace.ID?#>
//        )
    }

    func makeGridBody(libraryStyle: LibraryStyle) -> EmptyView {}

    func makeListBody(libraryStyle: LibraryStyle) -> EmptyView {}

    func makeBody(libraryStyle: LibraryStyle) -> EmptyView {
        EmptyView()
    }

    var preferredPosterDisplayType: PosterDisplayType {
        .landscape
    }

    var id: String {
        value
    }

    var systemImage: String {
        "bird.fill"
    }
}
