//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import SwiftUI

extension BlurHash {

    var averageLinearColor: Color {
        let color = averageLinearRGB
        return Color(
            red: Double(color.0),
            green: Double(color.1),
            blue: Double(color.2)
        )
    }
}
