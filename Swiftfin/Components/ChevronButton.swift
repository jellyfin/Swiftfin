//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ChevronButton: View {

    private let title: String
    private let subtitle: String?
    private var leadingView: () -> any View
    private var onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack {

                leadingView()
                    .eraseToAnyView()

                Text(title)
                    .foregroundColor(.primary)

                Spacer()

                if let subtitle {
                    Text(subtitle)
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.body.weight(.regular))
                    .foregroundColor(.secondary)
            }
        }
    }
}

extension ChevronButton {

    init(title: String, subtitle: String? = nil) {
        self.init(
            title: title,
            subtitle: subtitle,
            leadingView: { EmptyView() },
            onSelect: {}
        )
    }

    func leadingView(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.leadingView, with: content)
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
