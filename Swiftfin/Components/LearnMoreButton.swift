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
        Button {
            isPresented = true
        } label: {
            Group {
                if let footerText = footer {
                    Text("\(footerText) ")
                        .foregroundColor(.secondary)
                        + Text(L10n.learnMoreEllipsis)
                } else {
                    Text(L10n.learnMoreEllipsis)
                }
            }
            .font(.footnote)
            .foregroundColor(Color.accentColor)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheet(isPresented: $isPresented) {
            learnMoreView
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
