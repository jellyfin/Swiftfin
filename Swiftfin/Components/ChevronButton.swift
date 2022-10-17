//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ChevronButton: View {

    let title: String
    let subtitle: String?
    private var onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack {
                Text(title)
                    .foregroundColor(.primary)

                Spacer()

                if let subtitle {
                    Text(subtitle)
                        .foregroundColor(.gray)
                }

                Image(systemName: "chevron.right")
            }
        }
    }
}

extension ChevronButton {
    init(title: String, subtitle: String? = nil) {
        self.init(
            title: title,
            subtitle: subtitle,
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
