//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ProgramsView {

    struct ProgramProgressOverlay: View {

        @State
        private var programProgress: Double = 0.0

        let program: BaseItemDto
        private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

        var body: some View {
            WrappedView {
                if let startDate = program.startDate, startDate < Date.now {
                    LandscapePosterProgressBar(
                        progress: program.programProgress ?? 0
                    )
                }
            }
            .onReceive(timer) { newValue in
                if let startDate = program.startDate, startDate < newValue, let duration = program.programDuration {
                    programProgress = newValue.timeIntervalSince(startDate) / duration
                }
            }
        }
    }
}
