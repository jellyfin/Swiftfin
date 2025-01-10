//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct Video3DFormatPicker: View {
    let title: String
    @Binding
    var selectedFormat: Video3DFormat?

    var body: some View {
        Picker(title, selection: $selectedFormat) {
            Text(L10n.none).tag(nil as Video3DFormat?)
            ForEach(Video3DFormat.allCases, id: \.self) { format in
                Text(format.displayTitle).tag(format as Video3DFormat?)
            }
        }
    }
}
