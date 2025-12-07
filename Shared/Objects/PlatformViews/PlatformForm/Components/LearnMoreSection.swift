//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct LearnMoreSection<Content: View, Footer: View, LearnMore: View>: PlatformView {

    let title: String
    let content: Content
    let footer: Footer?
    let learnMore: LearnMore

    // MARK: - Initializer

    init(
        _ title: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer,
        @LabeledContentBuilder learnMore: () -> LearnMore
    ) {
        self.title = title
        self.content = content()
        self.footer = footer()
        self.learnMore = learnMore()
    }

    init(
        _ title: String,
        @ViewBuilder content: () -> Content,
        @LabeledContentBuilder learnMore: () -> LearnMore
    ) where Footer == EmptyView {
        self.title = title
        self.content = content()
        self.footer = nil
        self.learnMore = learnMore()
    }

    // MARK: - iOS View

    var iOSView: some View {
        Section {
            content
        } header: {
            Text(title)
        } footer: {
            VStack(alignment: .leading) {
                footer
                _LearnMoreButton(title: title, learnMore: learnMore)
            }
        }
    }

    // MARK: - tvOS View

    var tvOSView: some View {
        Section {
            content
                .focusedValue(\.formLearnMore, learnMore.eraseToAnyView())
        } header: {
            Text(title)
        } footer: {
            footer
        }
    }
}

// TODO: Rename to `LearnMoreButton` once the original `LearnMoreButton` is removed
private struct _LearnMoreButton<LearnMore: View>: View {

    @State
    private var isPresented = false

    let title: String
    let learnMore: LearnMore

    var body: some View {
        Button(L10n.learnMore + "\u{2026}") {
            isPresented = true
        }
        .foregroundStyle(Color.accentColor)
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                ScrollView {
                    SeparatorVStack(alignment: .leading) {
                        Divider()
                            .padding(.vertical, 8)
                    } content: {
                        learnMore
                            .labeledContentStyle(LearnMoreLabeledContentStyle())
                            .foregroundStyle(Color.primary, Color.secondary)
                    }
                    .edgePadding()
                }
                .navigationTitle(title.localizedCapitalized)
                .navigationBarTitleDisplayMode(.inline)
                #if os(iOS)
                    .navigationBarCloseButton {
                        isPresented = false
                    }
                #endif
            }
        }
    }
}
