//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SeeAllButton: View {

    private var onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack {
                L10n.seeAll.text
                Image(systemName: "chevron.right")
            }
            .font(.subheadline.bold())
        }
    }
}

extension SeeAllButton {
    init() {
        self.onSelect = {}
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onSelect = action
        return copy
    }
}
