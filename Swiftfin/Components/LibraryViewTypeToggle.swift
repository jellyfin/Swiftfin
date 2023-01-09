//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct LibraryViewTypeToggle: View {

    @Binding
    var libraryViewType: LibraryViewType

    var body: some View {
        Button {
            switch libraryViewType {
            case .grid:
                libraryViewType = .list
            case .list:
                libraryViewType = .grid
            }
        } label: {
            switch libraryViewType {
            case .grid:
                Image(systemName: "list.dash")
            case .list:
                Image(systemName: "square.grid.2x2")
            }
        }
    }
}
