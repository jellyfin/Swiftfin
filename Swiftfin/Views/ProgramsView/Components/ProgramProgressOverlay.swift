//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: move to where poster overlay is injected into environment

// TODO: item-type dependent views may be more appropriate near/on
//       the `PosterButton` object instead of on these larger views
extension ProgramsView {

    struct ProgramProgressOverlay: View {

        @State
        private var programProgress: Double = 0.0

        let program: BaseItemDto
        private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

        var body: some View {
            ZStack {
                if let startDate = program.startDate, startDate < Date.now {
//                    LandscapePosterProgressBar(
//                        progress: program.programProgress ?? 0
//                    )
                }
            }
            .onReceive(timer) { newValue in
                if let startDate = program.startDate, startDate < newValue, let duration = program.programDuration {
                    programProgress = clamp(newValue.timeIntervalSince(startDate) / duration, min: 0, max: 1)
                }
            }
        }
    }
}
