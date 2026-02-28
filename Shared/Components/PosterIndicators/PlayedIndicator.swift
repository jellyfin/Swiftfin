//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct PlayedIndicator: View {

    @Default(.accentColor)
    private var accentColor

    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .resizable()
            .symbolRenderingMode(.palette)
            .foregroundStyle(accentColor.overlayColor, accentColor)
            .frame(width: 25, height: 25)
    }
}
