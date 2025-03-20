//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

struct FontPickerView: View {

    @Binding
    var selection: String

    var body: some View {
        SelectorView(
            selection: $selection,
            sources: UIFont.familyNames
        )
        .label { fontFamily in
            Text(fontFamily)
                .foregroundColor(.primary)
                .font(.custom(fontFamily, size: 18))
        }
        .navigationTitle(L10n.subtitleFont)
    }
}
