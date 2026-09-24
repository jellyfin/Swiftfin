//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct NowPlayingIndicator: View {

    @Environment(\.isEnabled)
    private var isEnabled

    @State
    private var resumedAt: Date = .now

    private let restingScale = 0.25

    var body: some View {
        TimelineView(.animation(paused: !isEnabled)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let ramp = min(1, max(0, context.date.timeIntervalSince(resumedAt) / 0.4))

            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0 ..< 4) { index in
                    let phase = time * (3.25 + Double(index) * 0.5) + Double(index) * 1.7
                    let scale = restingScale + (1 - restingScale) * (sin(phase) + 1) / 2

                    Capsule()
                        .scaleEffect(
                            y: isEnabled ? restingScale + (scale - restingScale) * ramp : restingScale,
                            anchor: .bottom
                        )
                }
            }
        }
        .animation(isEnabled ? nil : .easeInOut(duration: 0.3), value: isEnabled)
        .onChange(of: isEnabled) { _, isEnabled in
            guard isEnabled else { return }
            resumedAt = .now
        }
    }
}
