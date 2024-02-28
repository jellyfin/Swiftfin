//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: Move to LibraryView/Components

struct LibraryViewTypeToggle: View {

    @Binding
    private var libraryViewType: LibraryViewType

    @Environment(\.libraryViewTypes)
    private var libraryViewTypes

    init(libraryViewType: Binding<LibraryViewType>) {
        self._libraryViewType = libraryViewType
    }

    var body: some View {
        Menu {

            if libraryViewTypes.contains(.landscapeGrid) {
                Button {
                    libraryViewType = .landscapeGrid
                } label: {
                    Label("Landscape", systemImage: "rectangle")
                }
            }

            if libraryViewTypes.contains(.portraitGrid) {
                Button {
                    libraryViewType = .portraitGrid
                } label: {
                    Label("Portrait", systemImage: "rectangle.portrait")
                }
            }

            if libraryViewTypes.contains(.list) {
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
