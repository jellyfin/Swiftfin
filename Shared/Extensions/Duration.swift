//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

@inlinable
func abs(_ d: Duration) -> Duration {
    d < .zero ? (.zero - d) : d
}

extension Duration {

    /// Represent Jellyfin ticks as a Duration
    static func ticks(_ ticks: Int) -> Duration {
        Duration.microseconds(Int64(ticks) / 10)
    }

    static func minutes(_ minutes: some BinaryInteger) -> Duration {
        .seconds(Int64(minutes) * 60)
    }

    static func minutes(_ minutes: some BinaryFloatingPoint) -> Duration {
        .seconds(Double(minutes) * 60)
    }

    static func hours(_ hours: some BinaryInteger) -> Duration {
        .seconds(Int64(hours) * 3600)
    }

    static func hours(_ hours: some BinaryFloatingPoint) -> Duration {
        .seconds(Double(hours) * 3600)
    }

    var microseconds: Int64 {
        (components.attoseconds / 1_000_000_000_000) + components.seconds * 1_000_000
    }

    var seconds: Double {
        Double(components.seconds) + Double(components.attoseconds) * 1e-18
    }

    var minutes: Double {
        seconds / 60
    }

    var hours: Double {
        seconds / 3600
    }

    var ticks: Int {
        Int(microseconds * 10)
    }

    /// Represent the hour and minute components of a date as Duration
    static func timeOfDay(_ date: Date) -> Duration {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return .seconds((hour * 3600) + (minute * 60))
    }

    /// Represent this Duration as a date with only hour and minute components
    var timeOfDayDate: Date {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        var components = DateComponents()
        components.hour = hours
        components.minute = minutes

        return Calendar.current.date(from: components) ?? Date()
    }
}
