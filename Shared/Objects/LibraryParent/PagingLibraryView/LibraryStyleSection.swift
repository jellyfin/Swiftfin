//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension PagingLibraryView {

    struct LibraryStyleSection: View {

        @StateObject
        private var box: BindingBox<LibraryStyle>

        private var libraryStyle: Binding<LibraryStyle> {
            $box.value
        }

        init(libraryStyle: Binding<LibraryStyle>) {
            self._box = StateObject(wrappedValue: BindingBox(source: libraryStyle))
        }

        var body: some View {
            Picker(selection: libraryStyle.displayType) {
                ForEach(LibraryDisplayType.allCases, id: \.self) { displayType in
                    Label(
                        displayType.displayTitle,
                        systemImage: displayType.systemImage
                    )
                    .tag(displayType)
                }
            } label: {
                Text(L10n.layout)

                Text(libraryStyle.wrappedValue.displayType.displayTitle)

                Image(systemName: libraryStyle.wrappedValue.displayType.systemImage)
            }
            .pickerStyle(.menu)

//                    if libraryStyle.wrappedValue.displayType == .list, UIDevice.isPad {
//                        Divider()
//
//                        Stepper(
//                            L10n.columnsWithCount(libraryStyle.wrappedValue.listColumnCount),
//                            value: libraryStyle.listColumnCount,
//                            in: 1 ... 3
//                        )
//                    }
//                }

            Picker(selection: libraryStyle.posterDisplayType) {
                ForEach(PosterDisplayType.allCases, id: \.self) { displayType in
                    Label(
                        displayType.displayTitle,
                        systemImage: displayType.systemImage
                    )
                    .tag(displayType)
                }
            } label: {
                Text(L10n.posters)

                Text(libraryStyle.wrappedValue.posterDisplayType.displayTitle)

                Image(systemName: libraryStyle.wrappedValue.posterDisplayType.systemImage)
            }
            .pickerStyle(.menu)
        }
    }
}
