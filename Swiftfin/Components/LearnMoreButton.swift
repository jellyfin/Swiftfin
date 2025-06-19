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
    private let content: AnyView

    // MARK: - Initializer

    init(
        _ title: String,
        @LabeledContentBuilder content: () -> AnyView
    ) {
        self.title = title
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        Button(L10n.learnMore + "\u{2026}") {
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
        NavigationStack {
            ScrollView {
                SeparatorVStack(alignment: .leading) {
                    Divider()
                        .padding(.vertical, 8)
                } content: {
                    content
                        .labeledContentStyle(LearnMoreLabeledContentStyle())
                        .foregroundStyle(Color.primary, Color.secondary)
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
