//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct LearnMore: View {
    @State
    private var isPresented: Bool = false

    let title: String
    let itemDescriptions: [TextPair]

    // MARK: - Initializer

    init(_ title: String, @ArrayBuilder<TextPair> items: () -> [TextPair]) {
        self.title = title
        self.itemDescriptions = items()
    }

    // MARK: - Body

    var body: some View {
        Button(action: {
            isPresented = true
        }) {
            Text(L10n.learnMoreEllipsis)
                .foregroundColor(.accentColor)
                .font(.subheadline)
        }
        .sheet(isPresented: $isPresented) {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(itemDescriptions) { content in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(content.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text(content.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 12)
                            }
                            Divider()
                        }
                    }
                    .padding()
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarCloseButton {
                    isPresented = false
                }
            }
        }
    }
}
