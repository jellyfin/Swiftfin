//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

private let landscapeWidth: CGFloat = 110
private let portraitWidth: CGFloat = 60

protocol LibraryElement: Displayable, LibraryIdentifiable, Poster {

    associatedtype GridBody: View = EmptyView
    associatedtype ListBody: View = EmptyView

    func libraryDidSelectElement(router: Router.Wrapper, in namespace: Namespace.ID)

    @MainActor
    @ViewBuilder
    func makeGridBody(libraryStyle: LibraryStyle) -> GridBody

    @MainActor
    @ViewBuilder
    func makeListBody(libraryStyle: LibraryStyle) -> ListBody
}
