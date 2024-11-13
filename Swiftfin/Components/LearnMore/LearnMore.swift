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
    let itemDescriptions: [ItemDescription]

    // MARK: - Body

    init(_ title: String, items: [ItemDescription]) {
        self.title = title
        self.itemDescriptions = items
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
                    ForEach(itemDescriptions) { content in
                        VStack(alignment: .leading, spacing: 16) {
                            Text(content.item)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text(content.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 12)

                            Divider()
                        }
                        .padding(.bottom, 8)
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                    .padding()
                }
                .padding(.horizontal, 16)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarCloseButton {
                    isPresented = false
                }
            }
        }
    }
}
