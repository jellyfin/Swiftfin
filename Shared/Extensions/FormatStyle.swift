//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: break into separate files

struct MinuteSecondsFormatStyle: FormatStyle {

    func format(_ value: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.minute, .second]
        return formatter.string(from: value) ?? .emptyDash
    }
}

extension FormatStyle where Self == MinuteSecondsFormatStyle {

    @available(*, deprecated, message: "Use `Duration` instead.")
    static var minuteSeconds: MinuteSecondsFormatStyle { MinuteSecondsFormatStyle() }
}

extension FormatStyle where Self == Duration.UnitsFormatStyle {

    static var minuteSecondsAbbreviated: Duration.UnitsFormatStyle {
        Duration.UnitsFormatStyle(
            allowedUnits: [.minutes, .seconds],
            width: .abbreviated
        )
    }

    static var hourMinuteAbbreviated: Duration.UnitsFormatStyle {
        Duration.UnitsFormatStyle(
            allowedUnits: [.hours, .minutes],
            width: .abbreviated
        )
    }

    static var minuteSecondsNarrow: Duration.UnitsFormatStyle {
        Duration.UnitsFormatStyle(
            allowedUnits: [.minutes, .seconds],
            width: .narrow
        )
    }
}

struct RuntimeFormatStyle: FormatStyle {

    func format(_ value: Duration) -> String {

        let formatStyle: Duration.TimeFormatStyle

        if value.components.seconds.magnitude >= 3600 {
            formatStyle = Duration.TimeFormatStyle(pattern: .hourMinuteSecond)
        } else {
            formatStyle = Duration.TimeFormatStyle(pattern: .minuteSecond)
        }

        return formatStyle.format(value)
    }
}

extension FormatStyle where Self == RuntimeFormatStyle {

    static var runtime: RuntimeFormatStyle {
        RuntimeFormatStyle()
    }
}

struct VerbatimFormatStyle<Value: CustomStringConvertible>: FormatStyle {

    func format(_ value: Value) -> String {
        value.description
    }
}

struct DisplayableFormatStyle<Value: Displayable>: FormatStyle {

    func format(_ value: Value) -> String {
        value.displayTitle
    }
}

extension FormatStyle where Self == PlaybackRateStyle {

    static var playbackRate: PlaybackRateStyle {
        PlaybackRateStyle()
    }
}

struct PlaybackRateStyle: FormatStyle {

    func format(_ value: Float) -> String {
        FloatingPointFormatStyle<Float>()
            .precision(.significantDigits(1 ... 3))
            .format(value)
            .appending("\u{00D7}")
    }
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

// TODO: remove after iOS 15 support dropped and use `Duration`
//       types and format styles instead

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

        // issue: not a closed interval
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

extension FormatStyle where Self == AgeFormatStyle {

    static var age: AgeFormatStyle { AgeFormatStyle() }
}

struct AgeFormatStyle: FormatStyle {

    private var death: Date?

    func death(_ date: Date?) -> AgeFormatStyle {
        copy(self, modifying: \.death, to: date)
    }

    func format(_ value: Date) -> String {
        let age = Calendar.current.dateComponents([.year], from: value, to: death ?? .now).year ?? 0
        return L10n.yearsOld(age)
    }
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
