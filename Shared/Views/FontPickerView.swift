//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FontPickerView: PlatformView {

    let selection: Binding<String>

    private var elements: [DisplayableBox<String>] {
        UIFont.familyNames
            .map(DisplayableBox.init)
    }

    var iOSView: some View {
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
                .font(.custom(fontFamily.displayTitle, size: UIDevice.isTV ? 30 : 18))
        }
        .navigationTitle(L10n.subtitleFont.localizedCapitalized)
    }

    var tvOSView: some View {
        Form(systemImage: "textformat.characters") {
            iOSView
        }
        .navigationTitle(L10n.subtitleFont.localizedCapitalized)
    }
}
