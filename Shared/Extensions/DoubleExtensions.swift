//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation

extension Double {

    func subtract(_ other: Double, floor: Double) -> Double {
        var v = self - other

        if v < floor {
            v += abs(floor - v)
        }

        return v
    }

    var timeLabel: String {
        let hours = floor(magnitude / 3600)
        let minutes = magnitude.truncatingRemainder(dividingBy: 3600) / 60
        let seconds = magnitude.truncatingRemainder(dividingBy: 3600).truncatingRemainder(dividingBy: 60)

        let hourText = hours > 0 ? String(Int(hours)).appending(":") : ""
        let minutesText = hours > 0 ? String(Int(minutes)).leftPad(toWidth: 2, withString: "0").appending(":") : String(Int(minutes))
            .appending(":")
        let secondsText = String(Int(floor(seconds))).leftPad(toWidth: 2, withString: "0")

        return hourText
            .appending(minutesText)
            .appending(secondsText)
    }
}
