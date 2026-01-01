//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

// TODO: replace all with formatters or use Duration

extension FixedWidthInteger {

    var timeLabel: String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 3600 % 60

        let hourText = hours > 0 ? String(hours).appending(":") : ""
        let minutesText = hours > 0 ? String(minutes).leftPad(maxWidth: 2, with: "0").appending(":") : String(minutes)
            .appending(":")
        let secondsText = String(seconds).leftPad(maxWidth: 2, with: "0")

        return hourText
            .appending(minutesText)
            .appending(secondsText)
    }
}

extension Int {

    /// Label if the current value represents milliseconds
    var millisecondLabel: String {
        let isNegative = self < 0
        let value = abs(self)
        let seconds = "\(value / 1000)"
        let milliseconds = "\(value % 1000)".first ?? "0"

        return seconds
            .appending(".")
            .appending(milliseconds)
            .appending("s")
            .prepending("-", if: isNegative)
    }

    /// Label if the current value represents seconds
    var secondLabel: String {
        let isNegative = self < 0
        let value = abs(self)
        let seconds = "\(value)"

        return seconds
            .appending("s")
            .prepending("-", if: isNegative)
    }

    init?(_ source: CGFloat?) {
        if let source = source {
            self.init(source)
        } else {
            return nil
        }
    }
}

struct MilliseondFormatter: FormatStyle {

    func format(_ value: Int) -> String {
        let isNegative = value < 0
        let value = abs(value)
        let seconds = "\(value / 1000)"
        let milliseconds = "\(value % 1000)".first ?? "0"

        return seconds
            .appending(".")
            .appending(milliseconds)
            .appending("s")
            .prepending("-", if: isNegative)
    }
}

struct SecondFormatter: FormatStyle {

    func format(_ value: Int) -> String {
        let isNegative = value < 0
        let value = abs(value)
        let seconds = "\(value)"

        return seconds
            .appending("s")
            .prepending("-", if: isNegative)
    }
}
