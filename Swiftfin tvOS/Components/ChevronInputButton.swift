//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ChevronInputButton<Content>: View where Content: View {

    @State
    private var isSelected = false

    private let title: Text
    private let subtitle: Text?
    private var leadingView: () -> any View
    private let menu: () -> Content
    private let onSave: (() -> Void)?
    private let onCancel: (() -> Void)?
    private let description: String?

    // MARK: - Initializer: String Title, String Subtitle, Optional Description, and Menu / Optional Save/Cancel Actions

    init(
        title: String,
        subtitle: String,
        description: String? = nil,
        @ViewBuilder menu: @escaping () -> Content,

        onSave: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.title = Text(title)
        self.subtitle = Text(subtitle)
        self.description = description
        self.leadingView = { EmptyView() }
        self.menu = menu
        self.onSave = onSave
        self.onCancel = onCancel
    }

    // MARK: - Initializer: String Title, Text Subtitle, Optional Description, and Menu / Optional Save/Cancel Actions

    init(
        title: String,
        subtitleText: Text,
        description: String? = nil,
        @ViewBuilder menu: @escaping () -> Content,
        onSave: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.title = Text(title)
        self.subtitle = subtitleText
        self.description = description
        self.leadingView = { EmptyView() }
        self.menu = menu
        self.onSave = onSave
        self.onCancel = onCancel
    }

    // MARK: - Initializer: Text Title, String Subtitle, Optional Description, and Menu / Optional Save/Cancel Actions

    init(
        titleText: Text,
        subtitle: String,
        description: String? = nil,
        @ViewBuilder menu: @escaping () -> Content,
        onSave: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.title = titleText
        self.subtitle = Text(subtitle)
        self.description = description
        self.leadingView = { EmptyView() }
        self.menu = menu
        self.onSave = onSave
        self.onCancel = onCancel
    }

    // MARK: - Initializer: Text Title, Text Subtitle, Optional Description, and Menu / Optional Save/Cancel Actions

    init(
        titleText: Text,
        subtitleText: Text,
        description: String? = nil,
        @ViewBuilder menu: @escaping () -> Content,
        onSave: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.title = titleText
        self.subtitle = subtitleText
        self.description = description
        self.leadingView = { EmptyView() }
        self.menu = menu
        self.onSave = onSave
        self.onCancel = onCancel
    }

    // MARK: - Leading View Customization

    func leadingView(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        var copy = self
        copy.leadingView = content
        return copy
    }

    // MARK: - Body

    var body: some View {
        Button {
            isSelected = true
        } label: {
            HStack {
                leadingView()
                    .eraseToAnyView()

                title
                    .foregroundColor(.primary)

                Spacer()

                if let subtitle {
                    subtitle
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.body.weight(.regular))
                    .foregroundColor(.secondary)
            }
        }
        .alert(title, isPresented: $isSelected) {
            menu()

            Button(L10n.save) {
                onSave?()
                isSelected = false
            }
            Button(L10n.cancel, role: .cancel) {
                onCancel?()
                isSelected = false
            }
        } message: {
            if let description = description {
                Text(description)
            }
        }
    }
}
