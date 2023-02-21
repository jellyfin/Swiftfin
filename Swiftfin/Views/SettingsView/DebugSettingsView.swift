//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

#if DEBUG
struct DebugSettingsView: View {

    @Default(.sendProgressReports)
    private var sendProgressReports

    var body: some View {
        Form {

            Toggle("Send Progress Reports", isOn: $sendProgressReports)
        }
    }
}
#endif
