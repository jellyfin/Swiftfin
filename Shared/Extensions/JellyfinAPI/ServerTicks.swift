//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

// TODO: remove and have sdk use strong types instead

typealias ServerTicks = Int

extension ServerTicks {

    // MARK: - Conversion Constants

    private static let ticksPerSecond = 10_000_000
    private static let ticksPerMinute = 600_000_000
    private static let ticksPerHour = 36_000_000_000
    private static let ticksPerDay = 864_000_000_000

    // MARK: - Initializers

    init(_ ticks: Int? = nil) {
        self = ticks ?? 0
    }

    init(seconds: Int? = nil) {
        self = (seconds ?? 0) * ServerTicks.ticksPerSecond
    }

    init(minutes: Int? = nil) {
        self = (minutes ?? 0) * ServerTicks.ticksPerMinute
    }

    init(hours: Int? = nil) {
        self = (hours ?? 0) * ServerTicks.ticksPerHour
    }

    init(days: Int? = nil) {
        self = (days ?? 0) * ServerTicks.ticksPerDay
    }

    init(timeInterval: TimeInterval? = nil) {
        self = Int((timeInterval ?? 0) * Double(ServerTicks.ticksPerSecond))
    }

    init(date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let totalSeconds = TimeInterval(hour * 3600 + minute * 60)
        self = Int(totalSeconds * 10_000_000)
    }

    // MARK: - Computed Properties

    var ticks: Int {
        self
    }

    var seconds: TimeInterval {
        TimeInterval(self) / Double(ServerTicks.ticksPerSecond)
    }

    var minutes: TimeInterval {
        TimeInterval(self) / Double(ServerTicks.ticksPerMinute)
    }

    var hours: TimeInterval {
        TimeInterval(self) / Double(ServerTicks.ticksPerHour)
    }

    var days: TimeInterval {
        TimeInterval(self) / Double(ServerTicks.ticksPerDay)
    }

    var date: Date {
        let totalSeconds = TimeInterval(self) / 10_000_000
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        var components = DateComponents()
        components.hour = hours
        components.minute = minutes
        return Calendar.current.date(from: components) ?? Date()
    }
}
