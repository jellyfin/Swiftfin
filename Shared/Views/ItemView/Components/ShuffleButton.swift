//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ShuffleButton: View {

    @PlayMedia
    private var playMedia

    let item: BaseItemDto

    var body: some View {
        if item.canShuffle {
            Button(ItemActionButton.shuffle.displayTitle, systemImage: ItemActionButton.shuffle.systemImage) {
                playMedia(intent: PlaybackIntent(item: item, queue: ShuffleMediaPlayerQueue(parent: item)))
            }
        }
    }
}
