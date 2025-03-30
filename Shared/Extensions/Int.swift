//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

extension Int {

    // TODO: convert to `FormatStyle`s

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

    // TODO: remove and have as formatter in `Text`

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
