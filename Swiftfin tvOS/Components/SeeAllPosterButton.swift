//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SeeAllPosterButton: View {

    private let type: PosterType
    private var onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            ZStack {
                Color(UIColor.darkGray)
                    .opacity(0.5)

                VStack(spacing: 20) {
                    Image(systemName: "chevron.right")
                        .font(.title)

                    L10n.seeAll.text
                        .font(.title3)
                }
            }
            .posterStyle(type)
        }
        .buttonStyle(.card)
    }
}

extension SeeAllPosterButton {

    init(type: PosterType) {
        self.init(
            type: type,
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
