//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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

    private var isNegated: Bool = false

    var negated: RunTimeFormatStyle {
        copy(self, modifying: \.isNegated, to: true)
    }

    func format(_ value: TimeInterval) -> String {
        let value = Int(value)

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
            .prepending("-", if: isNegated)
    }
}

extension FormatStyle where Self == RunTimeFormatStyle {

    static var runtime: RunTimeFormatStyle { RunTimeFormatStyle() }
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

extension FormatStyle where Self == RateStyle {

    static var rate: RateStyle {
        RateStyle()
    }
}

struct RateStyle: FormatStyle {

    func format(_ value: TimeInterval) -> String {
        String(format: "%.2f", value)
            .appending("x")
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
