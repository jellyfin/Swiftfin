//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import SwiftUI

extension PagingLibraryView {

    struct LibraryStyleSection: View {

        @StateOrBinding
        private var libraryStyle: LibraryStyle

        private let options: LibraryStyleOptions

        init(
            libraryStyle: Binding<LibraryStyle>,
            options: LibraryStyleOptions
        ) {
            self._libraryStyle = .init(libraryStyle)
            self.options = options
        }

        var body: some View {
            if options.displayTypes.count > 1 {
                Picker(selection: $libraryStyle.displayType) {
                    ForEach(options.displayTypes, id: \.self) { displayType in
                        Label(
                            displayType.displayTitle,
                            systemImage: displayType.systemImage
                        )
                        .tag(displayType)
                    }
                } label: {
                    Text(L10n.layout)

                    Text(libraryStyle.displayType.displayTitle)

                    Image(systemName: libraryStyle.displayType.systemImage)
                }
                .pickerStyle(.menu)
            }

            if libraryStyle.displayType == .list,
               UIDevice.isPad,
               options.displayTypes.contains(.list)
            {
                Stepper(
                    L10n.columnsWithCount(libraryStyle.listColumnCount),
                    value: $libraryStyle.listColumnCount,
                    in: 1 ... 3
                )
            }

            if options.posterDisplayTypes.count > 1 {
                Picker(selection: $libraryStyle.posterDisplayType) {
                    ForEach(options.posterDisplayTypes, id: \.self) { displayType in
                        Text(displayType.displayTitle)
                            .tag(displayType)
                    }
                } label: {
                    Text(L10n.posters)

                    Text(libraryStyle.posterDisplayType.displayTitle)
                }
                .pickerStyle(.menu)
            }
        }
    }
}
