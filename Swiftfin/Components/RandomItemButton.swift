//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct RandomItemButton: View {

    private var onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            Label(L10n.random, systemImage: "dice.fill")
        }
    }
}

extension RandomItemButton {
    init() {
        self.init(
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
