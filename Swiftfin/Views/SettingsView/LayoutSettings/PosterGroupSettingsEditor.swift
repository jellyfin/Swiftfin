//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PosterGroupSettingsEditor: View {

    @Binding
    private var displayType: PosterDisplayType
    @Binding
    private var size: PosterDisplayType.Size

    init(displayType: Binding<PosterDisplayType>, size: Binding<PosterDisplayType.Size>) {
        _displayType = displayType
        _size = size
    }

    init(settings: Binding<PosterGroupSettings>) {
        self.init(
            displayType: settings.displayType,
            size: settings.size.map(
                getter: \.posterSize,
                setter: { selected in
                    PosterSize.allCases.first { $0.posterSize == selected } ?? settings.wrappedValue.size
                }
            )
        )
    }

    @ContentBuilder
    var body: some View {
        Picker(L10n.style, selection: $displayType) {
            ForEach(PosterDisplayType.allCases, id: \.self) { type in
                Label(type.displayTitle, systemImage: type.systemImage)
                    .tag(type)
            }
        }

        Picker(L10n.size, selection: $size) {
            ForEach(PosterSize.allCases, id: \.self) { size in
                Text(size.displayTitle)
                    .tag(size.posterSize)
            }
        }
    }
}
