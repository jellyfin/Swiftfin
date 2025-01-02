//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $isPresented) {
            learnMoreView
        }
    }

    // MARK: - Learn More View

    private var learnMoreView: some View {
        NavigationView {
            ScrollView {
                SeparatorVStack(alignment: .leading) {
                    Divider()
                } content: {
                    ForEach(items) { content in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(content.title)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text(content.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 16)
                    }
                }
                .edgePadding(.horizontal)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                isPresented = false
            }
        }
        .foregroundStyle(Color.primary, Color.secondary)
    }
}
