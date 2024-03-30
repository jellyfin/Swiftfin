//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import SwiftUI

// TODO: allow "intervals" of times for other views to appear
//       - retry
struct DelayedProgressView: View {

    @State
    private var didLapse = false

    private let timer: Publishers.Autoconnect<Timer.TimerPublisher>

    init(delay: Double = 1) {
        self.timer = Timer.publish(every: delay, on: .main, in: .common).autoconnect()
    }

    var body: some View {
        VStack {
            if didLapse {
                ProgressView()
            }
        }
        .onReceive(timer) { _ in
            withAnimation {
                didLapse = true
            }
        }
    }
}
