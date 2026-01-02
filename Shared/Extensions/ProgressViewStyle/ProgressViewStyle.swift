//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ProgressViewStyle where Self == GaugeProgressViewStyle {

    static var gauge: GaugeProgressViewStyle {
        GaugeProgressViewStyle()
    }

    static func gauge(systemImage: String) -> GaugeProgressViewStyle {
        GaugeProgressViewStyle(systemImage: systemImage)
    }
}

extension ProgressViewStyle where Self == PlaybackProgressViewStyle {

    static var playback: Self { .init(secondaryProgress: nil, cornerStyle: .round) }

    func secondaryProgress(_ progress: Double?) -> Self {
        copy(self, modifying: \.secondaryProgress, to: progress)
    }

    var square: Self {
        copy(self, modifying: \.cornerStyle, to: .square)
    }
}
