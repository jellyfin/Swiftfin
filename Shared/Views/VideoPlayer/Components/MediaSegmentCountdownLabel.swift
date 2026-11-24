//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct MediaSegmentCountdownLabel: View {

    let duration: TimeInterval
    let deadline: Date?
    let remaining: TimeInterval

    @ContentBuilder
    var body: some View {
        Label {
            Text(L10n.cancel)
        } icon: {
            Image(systemName: "circle")
                .hidden()
                .overlay {
                    TimelineView(.animation(minimumInterval: 0.1, paused: deadline == nil)) { context in
                        let seconds = deadline?.timeIntervalSince(context.date) ?? remaining

                        ProgressView(value: seconds.clamped(to: 0 ... duration), total: duration)
                            .progressViewStyle(.gauge)
                    }
                }
        }
    }
}
