//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: break into separate files

struct HourMinuteFormatStyle: FormatStyle {

    func format(_ value: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: value) ?? .emptyDash
    }
}

extension FormatStyle where Self == HourMinuteFormatStyle {

    static var hourMinute: HourMinuteFormatStyle { HourMinuteFormatStyle() }
}

struct RunTimeFormatStyle: FormatStyle {

    private var negate: Bool = false

    var negated: RunTimeFormatStyle {
        mutating(\.negate, with: true)
    }

    func format(_ value: Int) -> String {
        let hours = value / 3600
        let minutes = (value % 3600) / 60
        let seconds = value % 3600 % 60

        let hourText = hours > 0 ? String(hours).appending(":") : ""
        let minutesText = hours > 0 ? String(minutes).leftPad(maxWidth: 2, with: "0").appending(":") : String(minutes)
            .appending(":")
        let secondsText = String(seconds).leftPad(maxWidth: 2, with: "0")

        return hourText
            .appending(minutesText)
            .appending(secondsText)
            .prepending("-", if: negate)
    }
}

extension FormatStyle where Self == RunTimeFormatStyle {

    static var runtime: RunTimeFormatStyle { RunTimeFormatStyle() }
}

/// Represent intervals as 24 hour, 60 minute, 60 second days
struct DayIntervalParseableFormatStyle: ParseableFormatStyle {

    let range: ClosedRange<Int>
    var parseStrategy: DayIntervalParseStrategy = .init()

    func format(_ value: TimeInterval) -> String {
        "\(clamp(Int(value / 86400), min: range.lowerBound, max: range.upperBound))"
    }
}

struct DayIntervalParseStrategy: ParseStrategy {

    func parse(_ value: String) throws -> TimeInterval {
        (TimeInterval(value) ?? 0) * 86400
    }
}

extension ParseableFormatStyle where Self == DayIntervalParseableFormatStyle {

    static func dayInterval(range: ClosedRange<Int>) -> DayIntervalParseableFormatStyle {
        .init(range: range)
    }
}

struct NilIfEmptyStringFormatStyle: ParseableFormatStyle {

    var parseStrategy: NilIfEmptyStringParseStrategy = .init()

    func format(_ value: String?) -> String {
        value ?? ""
    }
}

struct NilIfEmptyStringParseStrategy: ParseStrategy {

    func parse(_ value: String) -> String? {
        value.isEmpty ? nil : value
    }
}

extension ParseableFormatStyle where Self == NilIfEmptyStringFormatStyle {

    static var nilIfEmptyString: NilIfEmptyStringFormatStyle {
        .init()
    }
}

extension FormatStyle where Self == TimeIntervalFormatStyle {

    static func interval(
        style: Date.ComponentsFormatStyle.Style,
        fields: Set<Date.ComponentsFormatStyle.Field>
    ) -> TimeIntervalFormatStyle {
        TimeIntervalFormatStyle(style: style, fields: fields)
    }
}

struct TimeIntervalFormatStyle: FormatStyle {

    let style: Date.ComponentsFormatStyle.Style
    let fields: Set<Date.ComponentsFormatStyle.Field>

    func format(_ value: TimeInterval) -> String {
        let value = abs(value)
        let t = Date.now

        return Date.ComponentsFormatStyle(
            style: style,
            locale: .current,
            calendar: .current,
            fields: fields
        ).format(t ..< t.addingTimeInterval(value))
    }
}

struct LastSeenFormatStyle: FormatStyle {

    func format(_ value: Date?) -> String {

        guard let value else {
            return L10n.never
        }

        let timeInterval = Date.now.timeIntervalSince(value)
        let twentyFourHours: TimeInterval = 24 * 60 * 60

        if timeInterval <= twentyFourHours {
            return value.formatted(.relative(presentation: .numeric, unitsStyle: .narrow))
        } else {
            return value.formatted(Date.FormatStyle.dateTime.year().month().day())
        }
    }
}

extension FormatStyle where Self == LastSeenFormatStyle {

    static var lastSeen: LastSeenFormatStyle { LastSeenFormatStyle() }
}

struct IntBitRateFormatStyle: FormatStyle {
    func format(_ value: Int) -> String {
        let units = [
            L10n.bitsPerSecond,
            L10n.kilobitsPerSecond,
            L10n.megabitsPerSecond,
            L10n.gigabitsPerSecond,
            L10n.terabitsPerSecond,
        ]
        var adjustedValue = Double(value)
        var unitIndex = 0

        while adjustedValue >= 1000, unitIndex < units.count - 1 {
            adjustedValue /= 1000
            unitIndex += 1
        }

        let formattedValue = String(format: "%.1f", adjustedValue)
        return "\(formattedValue) \(units[unitIndex])"
    }
}

extension FormatStyle where Self == IntBitRateFormatStyle {
    static var bitRate: IntBitRateFormatStyle { IntBitRateFormatStyle() }
}
