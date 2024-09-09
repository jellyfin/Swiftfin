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

    let negate: Bool

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

extension FormatStyle where Self == HourMinuteFormatStyle {

    static var runtime: RunTimeFormatStyle { RunTimeFormatStyle(negate: false) }

    static func runtime(negate: Bool) -> RunTimeFormatStyle {
        RunTimeFormatStyle(negate: negate)
    }
}

struct VerbatimFormatStyle<Value: CustomStringConvertible>: FormatStyle {

    func format(_ value: Value) -> String {
        value.description
    }
}
