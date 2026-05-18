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

        private let content: () -> any View
        private let action: () -> Void
        private let title: String
        private let subtitle: String?

        var body: some View {
            Button {
                action()
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

        init(
            title: String,
            subtitle: String? = nil,
            @ViewBuilder content: @escaping () -> any View
        ) {
            self.init(
                title: title,
                subtitle: subtitle,
                action: {},
                content: content
            )
        }

        init(
            title: String,
            subtitle: String? = nil,
            action: @escaping () -> Void = {},
            @ViewBuilder content: @escaping () -> any View
        ) {
            self.content = content
            self.action = action
            self.title = title
            self.subtitle = subtitle
        }
    }
}
