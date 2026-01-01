//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct ListColumnsPickerView: View {

    @Binding
    var selection: Int

    var body: some View {
        StepperView(
            title: L10n.columns,
            value: $selection,
            range: 1 ... 3,
            step: 1
        )
    }
}
