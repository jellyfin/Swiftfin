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

struct MediaSegmentSettingsView: View {

    #if os(tvOS)
    typealias PlatformPicker = ListRowMenu
    #else
    typealias PlatformPicker = Picker
    #endif

    @Default(.VideoPlayer.mediaSegmentBehaviors)
    private var mediaSegmentBehaviors

    var body: some View {
        Form(systemImage: "forward.end") {
            Section {
                ForEach(MediaSegmentType.supportedCases, id: \.self) { segment in
                    PlatformPicker(segment.displayTitle, selection: mediaSegmentBinding(segment))
                }
            }
        }
        .navigationTitle(L10n.mediaSegments.localizedCapitalized)
    }

    private func mediaSegmentBinding(_ segment: MediaSegmentType) -> Binding<MediaSegmentBehavior> {
        Binding(
            get: { mediaSegmentBehaviors[segment] ?? .off },
            set: { mediaSegmentBehaviors[segment] = $0 }
        )
    }
}
