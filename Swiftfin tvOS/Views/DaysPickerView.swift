//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct DaysPickerView: View {

    @Binding
    var selection: Int

    var body: some View {
        StepperView(
            title: L10n.nextUpDays,
            value: $selection,
            range: 0 ... 999,
            step: 1
        )
        .valueFormatter { days in
            switch days {
            case 0:
                return L10n.disabled
            default:
                return days.dayLabel
            }
        }
    }
}
