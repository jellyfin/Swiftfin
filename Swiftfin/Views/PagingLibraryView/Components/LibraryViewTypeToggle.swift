//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: rename `LibraryDisplayTypeToggle`/Section
//       - change to 2 Menu's in a section with subtitle
//         like on `SelectUserView`?

extension PagingLibraryView {

    struct LibraryViewTypeToggle: View {

        @Binding
        private var listColumnCount: Int
        @Binding
        private var posterType: PosterDisplayType
        @Binding
        private var viewType: LibraryDisplayType

        init(
            posterType: Binding<PosterDisplayType>,
            viewType: Binding<LibraryDisplayType>,
            listColumnCount: Binding<Int>
        ) {
            self._listColumnCount = listColumnCount
            self._posterType = posterType
            self._viewType = viewType
        }

        var body: some View {
            Menu {

                Section("Poster") {
                    Button {
                        posterType = .landscape
                    } label: {
                        if posterType == .landscape {
                            Label("Landscape", systemImage: "checkmark")
                        } else {
                            Label("Landscape", systemImage: "rectangle")
                        }
                    }

                    Button {
                        posterType = .portrait
                    } label: {
                        if posterType == .portrait {
                            Label("Portrait", systemImage: "checkmark")
                        } else {
                            Label("Portrait", systemImage: "rectangle.portrait")
                        }
                    }
                }

                Section(L10n.layout) {
                    Button {
                        viewType = .grid
                    } label: {
                        if viewType == .grid {
                            Label(L10n.grid, systemImage: "checkmark")
                        } else {
                            Label(L10n.grid, systemImage: "square.grid.2x2.fill")
                        }
                    }

                    Button {
                        viewType = .list
                    } label: {
                        if viewType == .list {
                            Label(L10n.list, systemImage: "checkmark")
                        } else {
                            Label(L10n.list, systemImage: "square.fill.text.grid.1x2")
                        }
                    }
                }

                if viewType == .list, UIDevice.isPad {
                    Stepper("Columns: \(listColumnCount)", value: $listColumnCount, in: 1 ... 3)
                }
            } label: {
                switch viewType {
                case .grid:
                    Label(L10n.layout, systemImage: "square.grid.2x2.fill")
                case .list:
                    Label(L10n.layout, systemImage: "square.fill.text.grid.1x2")
                }
            }
        }
    }
}
