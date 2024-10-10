//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

struct ServerTicks {
    private var ticksValue: Int

    // MARK: - Conversion Constants

    private let ticksPerSecond = 10_000_000
    private let ticksPerMinute = 600_000_000
    private let ticksPerHour = 36_000_000_000
    private let ticksPerDay = 864_000_000_000

    // MARK: - Initializers

    init(ticks: Int? = nil) {
        self.ticksValue = ticks ?? 0
    }

    init(seconds: Int? = nil) {
        self.ticksValue = (seconds ?? 0) * ticksPerSecond
    }

    init(minutes: Int? = nil) {
        self.ticksValue = (minutes ?? 0) * ticksPerMinute
    }

    init(hours: Int? = nil) {
        self.ticksValue = (hours ?? 0) * ticksPerHour
    }

    init(days: Int? = nil) {
        self.ticksValue = (days ?? 0) * ticksPerDay
    }

    init(timeInterval: TimeInterval? = nil) {
        self.ticksValue = Int((timeInterval ?? 0) * Double(ticksPerSecond))
    }

    init(date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let totalSeconds = TimeInterval((components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60)
        self.ticksValue = Int(totalSeconds * 10_000_000)
    }

    // MARK: - Computed Properties

    var ticks: Int {
        ticksValue
    }

    var seconds: TimeInterval {
        TimeInterval(ticksValue) / Double(ticksPerSecond)
    }

    var minutes: TimeInterval {
        TimeInterval(ticksValue) / Double(ticksPerMinute)
    }

    var hours: TimeInterval {
        TimeInterval(ticksValue) / Double(ticksPerHour)
    }

    var days: TimeInterval {
        TimeInterval(ticksValue) / Double(ticksPerDay)
    }

    var date: Date {
        let totalSeconds = TimeInterval(ticksValue) / 10_000_000
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        var components = DateComponents()
        components.hour = hours
        components.minute = minutes
        return Calendar.current.date(from: components) ?? Date()
    }
}
