//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension PagingLibraryView {

    struct LibraryViewTypeToggle: View {

        @Binding
        private var libraryViewType: LibraryViewType
        @Binding
        private var listColumnCount: Int

        init(libraryViewType: Binding<LibraryViewType>, listColumnCount: Binding<Int>) {
            self._libraryViewType = libraryViewType
            self._listColumnCount = listColumnCount
        }

        var body: some View {
            Menu {

                Button {
                    libraryViewType = .landscapeGrid
                } label: {
                    if libraryViewType == .landscapeGrid {
                        Label("Landscape", systemImage: "checkmark")
                    } else {
                        Label("Landscape", systemImage: "rectangle")
                    }
                }

                Button {
                    libraryViewType = .portraitGrid
                } label: {
                    if libraryViewType == .portraitGrid {
                        Label("Portrait", systemImage: "checkmark")
                    } else {
                        Label("Portrait", systemImage: "rectangle.portrait")
                    }
                }

                if libraryViewType == .list, UIDevice.isPad {

                    Button {
                        libraryViewType = .list
                    } label: {
                        if libraryViewType == .list {
                            Label(L10n.list, systemImage: "checkmark")
                        } else {
                            Label(L10n.list, systemImage: "list.dash")
                        }
                    }

                    Stepper("Columns: \(listColumnCount)", value: $listColumnCount, in: 1 ... 4)
                } else {

                    Button {
                        libraryViewType = .list
                    } label: {
                        if libraryViewType == .list {
                            Label(L10n.list, systemImage: "checkmark")
                        } else {
                            Label(L10n.list, systemImage: "list.dash")
                        }
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
}
