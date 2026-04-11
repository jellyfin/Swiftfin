//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@inlinable
func abs(_ d: Duration) -> Duration {
    d < .zero ? (.zero - d) : d
}

extension Duration {

    /// Represent Jellyfin ticks as a Duration
    static func ticks(_ ticks: Int) -> Duration {
        Duration.microseconds(Int64(ticks) / 10)
    }

    var microseconds: Int64 {
        (components.attoseconds / 1_000_000_000_000) + components.seconds * 1_000_000
    }

    var seconds: Double {
        Double(components.seconds) + Double(components.attoseconds) * 1e-18
    }

    var ticks: Int {
        Int(microseconds * 10)
    }
}
