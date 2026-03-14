//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView.AboutView {

    struct Card: View {

        private var content: () -> any View
        private var onSelect: () -> Void
        private let title: String
        private let subtitle: String?

        var body: some View {
            Button {
                onSelect()
            } label: {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                    }

                    Spacer()
                        .frame(maxWidth: .infinity)

                    content()
                        .eraseToAnyView()
                }
                .padding()
                .frame(width: 700, height: 405)
            }
            .buttonStyle(.card)
        }
    }
}

extension ItemView.AboutView.Card {

    init(title: String, subtitle: String? = nil) {
        self.init(
            content: { EmptyView() },
            onSelect: {},
            title: title,
            subtitle: subtitle
        )
    }

    func content(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.content, with: content)
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
