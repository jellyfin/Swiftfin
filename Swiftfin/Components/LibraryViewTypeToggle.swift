//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct LibraryViewTypeToggle: View {

    @Binding
    var libraryViewType: LibraryViewType

    let allowedTypes: [LibraryViewType]

    init(libraryViewType: Binding<LibraryViewType>, allowedTypes: [LibraryViewType] = LibraryViewType.allCases) {
        self._libraryViewType = libraryViewType
        self.allowedTypes = allowedTypes
    }

    var body: some View {
        Menu {

            if allowedTypes.contains(.landscapeGrid) {
                Button {
                    libraryViewType = .landscapeGrid
                } label: {
                    Label("Landscape", systemImage: "rectangle")
                }
            }

            if allowedTypes.contains(.portraitGrid) {
                Button {
                    libraryViewType = .portraitGrid
                } label: {
                    Label("Portrait", systemImage: "rectangle.portrait")
                }
            }

            if allowedTypes.contains(.list) {
                Button {
                    libraryViewType = .list
                } label: {
                    Label(L10n.list, systemImage: "list.dash")
                }
            }
        } label: {
            switch libraryViewType {
            case .landscapeGrid:
                Label("Landscape", systemImage: "rectangle")
            case .portraitGrid:
                Label("Portrait", systemImage: "rectangle.portrait")
            case .list:
                Label(L10n.list, systemImage: "list.dash")
            }
        }
    }
}
