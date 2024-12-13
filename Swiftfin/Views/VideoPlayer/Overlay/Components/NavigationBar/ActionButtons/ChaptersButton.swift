//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.Overlay.NavigationBar.ActionButtons {

    struct ChaptersButton: View {

        @Environment(\.selectedMediaPlayerSupplement)
        private var selectedMediaPlayerSupplement

        @EnvironmentObject
        private var manager: MediaPlayerManager

        var body: some View {
            Button("Chapters", systemImage: "list.bullet") {
                selectedMediaPlayerSupplement.wrappedValue = MediaChaptersSupplement(chapters: manager.item.fullChapterInfo).asAny
            }
        }
    }
}
