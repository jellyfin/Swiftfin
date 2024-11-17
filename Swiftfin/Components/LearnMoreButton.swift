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
    private let footer: String?
    private let items: [TextPair]

    // MARK: - Initializer

    init(_ title: String, footer: String? = nil, @ArrayBuilder<TextPair> items: () -> [TextPair]) {
        self.title = title
        self.footer = footer
        self.items = items()
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            if let footerText = footer {
                Text(footerText)
                    .foregroundStyle(.primary)
            }

            Button(L10n.learnMoreEllipsis) {
                isPresented = true
            }
            .foregroundStyle(Color.accentColor)
            .font(.subheadline)
            .sheet(isPresented: $isPresented) {
                learnMoreView
            }
        }
    }

    // MARK: - Learn More View

    private var learnMoreView: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(items) { content in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(content.title)
                                .font(.headline)
                                .foregroundStyle(.foreground)

                            Text(content.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
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
