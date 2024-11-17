//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct LearnMoreButton: View {

    @State
    private var isPresented: Bool = false

    private let title: String
    private let items: [TextPair]

    // MARK: - Initializer

    init(_ title: String, @ArrayBuilder<TextPair> items: () -> [TextPair]) {
        self.title = title
        self.items = items()
    }

    // MARK: - Body

    var body: some View {
        Button(L10n.learnMoreEllipsis) {
            isPresented = true
        }
        .foregroundStyle(Color.accentColor)
        .font(.subheadline)
        .sheet(isPresented: $isPresented) {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(items) { content in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(content.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text(content.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Divider()
                        }
                    }
                    .edgePadding()
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
