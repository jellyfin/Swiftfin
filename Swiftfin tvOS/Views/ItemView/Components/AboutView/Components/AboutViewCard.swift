//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView.AboutView {

    struct Card<Content: View>: View {

        private var action: () -> Void
        private var content: Content
        private let title: String
        private let subtitle: String?

        init(
            title: String,
            subtitle: String? = nil,
            action: @escaping () -> Void,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.title = title
            self.subtitle = subtitle
            self.action = action
            self.content = content()
        }

        var body: some View {
            Button(action: action) {
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

                    content
                }
                .padding()
                .frame(width: 700, height: 405)
            }
            .buttonStyle(.card)
        }
    }
}
