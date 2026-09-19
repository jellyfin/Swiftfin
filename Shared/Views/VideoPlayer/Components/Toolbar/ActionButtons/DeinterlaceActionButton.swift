//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.PlaybackControls.Toolbar.ActionButtons {

    struct Deinterlace: View {

        // Bound to the global default, mirroring subtitle configuration. The VLC
        // view observes this and applies it to the player; a change here persists.
        @Default(.VideoPlayer.Playback.deinterlaceMode)
        private var deinterlaceMode

        // The 10 libVLC filters, in VLC's `mode_list[]` order.
        private var filterModes: [DeinterlaceMode] {
            DeinterlaceMode.allCases.filter { $0 != .off && $0 != .auto }
        }

        var body: some View {
            Menu {
                Picker(L10n.deinterlace, selection: $deinterlaceMode) {
                    Text(DeinterlaceMode.off.displayTitle).tag(DeinterlaceMode.off)
                    Text(DeinterlaceMode.auto.displayTitle).tag(DeinterlaceMode.auto)
                }
                .pickerStyle(.inline)

                Menu(L10n.filters) {
                    Picker(L10n.filters, selection: $deinterlaceMode) {
                        ForEach(filterModes, id: \.self) { mode in
                            Text(mode.displayTitle).tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                }
            } label: {
                Label(
                    L10n.deinterlace,
                    systemImage: VideoPlayerActionButton.deinterlace.systemImage
                )
            }
        }
    }
}
