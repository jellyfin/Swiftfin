//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension Section where Parent == Text, Footer == Text, Content: View {

    init(
        _ header: String,
        footer: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(content: content) {
            Text(header)
        } footer: {
            Text(footer)
        }
    }
}

// MARK: - Section Overloads

func Section(
    _ title: String,
    @ViewBuilder content: @escaping () -> some View,
    @LabeledContentBuilder learnMore: @escaping () -> AnyView
) -> some View {
    Section(
        title,
        content: content,
        footer: { EmptyView() },
        learnMore: learnMore
    )
}

func Section(
    _ title: String,
    @ViewBuilder content: @escaping () -> some View,
    @ViewBuilder footer: @escaping () -> some View,
    @LabeledContentBuilder learnMore: @escaping () -> AnyView
) -> some View {
    InlinePlatformView {
        Section {
            content()
        } header: {
            Text(title)
        } footer: {
            VStack(alignment: .leading) {
                footer()

                _LearnMoreButton(
                    title,
                    learnMore: learnMore
                )
            }
        }
    } tvOSView: {
        Section {
            content()
                .focusedValue(\.formLearnMore, learnMore())
        } header: {
            Text(title)
        } footer: {
            footer()
        }
    }
}

// MARK: - LearnMoreButton

// TODO: Rename to `LearnMoreButton` once the original `LearnMoreButton` is removed
private struct _LearnMoreButton: View {

    @State
    private var isPresented = false

    private let content: AnyView
    private let title: String

    init(
        _ title: String,
        @LabeledContentBuilder learnMore: @escaping () -> AnyView
    ) {
        self.content = learnMore()
        self.title = title
    }

    var body: some View {
        Button(L10n.learnMore + "\u{2026}") {
            isPresented = true
        }
        .foregroundStyle(Color.accentColor)
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
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
