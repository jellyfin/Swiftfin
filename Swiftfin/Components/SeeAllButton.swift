//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SeeAllButton: View {

    private var action: () -> Void

    var body: some View {
        Button(
            L10n.seeAll,
            systemImage: "chevron.right",
            action: action
        )
        .font(.subheadline.weight(.bold))
        .labelStyle(.titleAndIcon.trailingIcon)
    }
}

extension SeeAllButton {

    init() {
        self.init(
            action: {}
        )
    }

    func onSelect(perform action: @escaping () -> Void) -> Self {
        copy(modifying: \.action, with: action)
    }
}
