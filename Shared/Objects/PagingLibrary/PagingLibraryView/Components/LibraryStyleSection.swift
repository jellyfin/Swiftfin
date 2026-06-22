//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension PagingLibraryView {

    struct LibraryStyleSection: View {

        @StateObject
        private var box: BindingBox<LibraryStyle>

        private let options: LibraryStyleOptions

        private var libraryStyle: Binding<LibraryStyle> {
            options.binding($box.value)
        }

        init(
            libraryStyle: Binding<LibraryStyle>,
            options: LibraryStyleOptions
        ) {
            self._box = StateObject(wrappedValue: BindingBox(source: libraryStyle))
            self.options = options
        }

        var body: some View {
            if options.displayTypes.count > 1 {
                Picker(selection: libraryStyle.displayType) {
                    ForEach(options.displayTypes, id: \.self) { displayType in
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
            }

            if libraryStyle.wrappedValue.displayType == .list,
               UIDevice.isPad,
               options.displayTypes.contains(.list)
            {
                Stepper(
                    L10n.columnsWithCount(libraryStyle.wrappedValue.listColumnCount),
                    value: libraryStyle.listColumnCount,
                    in: 1 ... 3
                )
            }

            if options.posterDisplayTypes.count > 1 {
                Picker(selection: libraryStyle.posterDisplayType) {
                    ForEach(options.posterDisplayTypes, id: \.self) { displayType in
                        Text(displayType.displayTitle)
                            .tag(displayType)
                    }
                } label: {
                    Text(L10n.posters)

                    Text(libraryStyle.wrappedValue.posterDisplayType.displayTitle)
                }
                .pickerStyle(.menu)
            }
        }
    }
}
