//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

extension Int {

    @available(*, deprecated, message: "Use a `Duration` formatter instead")
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
