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

    let selection: Binding<String>

    private var elements: [DisplayableBox<String>] {
        UIFont.familyNames
            .map(DisplayableBox.init)
    }

    var body: some View {
        SelectorView(
            selection: selection.map(
                getter: DisplayableBox.init,
                setter: { $0.displayTitle }
            ),
            sources: elements
        )
        .label { fontFamily in
            Text(fontFamily.displayTitle)
                .foregroundColor(.primary)
                .font(.custom(fontFamily.displayTitle, size: 18))
        }
        .navigationTitle(L10n.subtitleFont.localizedCapitalized)
    }
}
