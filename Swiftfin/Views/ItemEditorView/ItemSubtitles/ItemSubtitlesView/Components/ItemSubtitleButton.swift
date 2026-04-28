//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemSubtitlesView {

    struct ItemSubtitleButton: View {

        @Environment(\.isEditing)
        private var isEditing
        @Environment(\.isSelected)
        private var isSelected

        let subtitle: MediaStream
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack {
                    Text(subtitle.displayTitle ?? L10n.unknown)
                        .foregroundStyle(isEditing && !isSelected ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ListRowCheckbox()
                }
            }
            .foregroundStyle(.primary, .secondary)
        }
    }
}
