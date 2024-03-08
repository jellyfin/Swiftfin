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
        private var listColumnCount: Int
        @Binding
        private var posterType: PosterType
        @Binding
        private var viewType: LibraryViewType

        init(
            posterType: Binding<PosterType>,
            viewType: Binding<LibraryViewType>,
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

                Section("Layout") {
                    Button {
                        viewType = .grid
                    } label: {
                        if viewType == .grid {
                            Label("Grid", systemImage: "checkmark")
                        } else {
                            Label("Grid", systemImage: "square.grid.2x2")
                        }
                    }

                    Button {
                        viewType = .list
                    } label: {
                        if viewType == .list {
                            Label("List", systemImage: "checkmark")
                        } else {
                            Label("List", systemImage: "square.fill.text.grid.1x2")
                        }
                    }
                }

                if viewType == .list, UIDevice.isPad {
                    Stepper("Columns: \(listColumnCount)", value: $listColumnCount, in: 1 ... 3)
                }
            } label: {
                switch viewType {
                case .grid:
                    Label("Layout", systemImage: "square.grid.2x2")
                case .list:
                    Label("Layout", systemImage: "square.fill.text.grid.1x2")
                }
            }
        }
    }
}
