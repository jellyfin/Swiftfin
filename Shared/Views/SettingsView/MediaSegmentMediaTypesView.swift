//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct MediaSegmentMediaTypesView: View {

    @Default(.VideoPlayer.mediaSegments)
    private var configuration

    private let mediaTypes = MediaSegmentConfiguration.default.itemTypes

    @ContentBuilder
    var body: some View {
        Form(systemImage: "forward.end") {
            Section(L10n.mediaTypes) {
                SelectorView(
                    selection: $configuration.itemTypes,
                    sources: mediaTypes,
                    type: .multi
                )
            }
        }
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.mediaTypes.localizedCapitalized)
        .topBarTrailing {
            Button(L10n.reset) {
                configuration.itemTypes = mediaTypes
            }
            .enabled(Set(configuration.itemTypes) != Set(mediaTypes))
        }
    }
}
