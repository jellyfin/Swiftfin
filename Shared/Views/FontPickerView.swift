//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FontPickerView: View {

    let selection: Binding<String>

    var body: some View {
        Form(systemImage: "textformat.characters") {
            SelectorView(
                selection: selection,
                sources: UIFont.familyNames
            ) { fontFamily in
                Text(fontFamily)
                    .font(.custom(fontFamily, size: UIDevice.isTV ? 30 : 18))
            }
        }
        .navigationTitle(L10n.subtitleFont.localizedCapitalized)
    }
}
