//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import SwiftUI

// TODO: retry button and/or loading text after a few more seconds
struct DelayedProgressView: View {

    @State
    private var interval = 0

    private let timer: Publishers.Autoconnect<Timer.TimerPublisher>

    init(interval: Double = 0.5) {
        self.timer = Timer.publish(every: interval, on: .main, in: .common).autoconnect()
    }

    var body: some View {
        VStack {
            if interval > 0 {
                ProgressView()
            }
        }
        .onReceive(timer) { _ in
            withAnimation {
                interval += 1
            }
        }
    }
}
