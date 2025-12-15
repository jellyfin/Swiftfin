//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension VideoPlayerSettingsView {
    struct MediaSegmentSection: View {

        @Default(.VideoPlayer.enableMediaSegments)
        private var enableMediaSegments

        @Default(.VideoPlayer.skipMediaSegments)
        private var skipMediaSegments
        @Default(.VideoPlayer.askMediaSegments)
        private var askMediaSegments

        var body: some View {
            Section(L10n.mediaSegments) {
                Toggle(L10n.enableMediaSegments, isOn: $enableMediaSegments)
            }

            Section {
                if enableMediaSegments {
                    ForEach(MediaSegmentType.allCases.sorted(by: { $0.displayTitle < $1.displayTitle }), id: \.self) { segment in
                        CaseIterablePicker(segment.displayTitle, selection: mediaSegmentBinding(segment))
                    }
                }
            }
        }

        private func mediaSegmentBinding(_ segment: MediaSegmentType) -> Binding<MediaSegmentBehavior> {
            Binding(
                get: {
                    if askMediaSegments.contains(segment) {
                        return .ask
                    } else if skipMediaSegments.contains(segment) {
                        return .skip
                    } else {
                        return .off
                    }
                },
                set: { newValue in
                    switch newValue {
                    case .off:
                        askMediaSegments.removeAll { $0 == segment }
                        skipMediaSegments.removeAll { $0 == segment }
                    case .ask:
                        askMediaSegments.append(segment)
                        skipMediaSegments.removeAll { $0 == segment }
                    case .skip:
                        askMediaSegments.removeAll { $0 == segment }
                        skipMediaSegments.append(segment)
                    }
                }
            )
        }
    }
}
