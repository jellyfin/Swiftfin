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
    private let description: String?
    private var leadingView: () -> any View
    private let menu: () -> Content
    private let onSave: (() -> Void)?
    private let onCancel: (() -> Void)?

    // MARK: - Initializer: String Inputs with Save/Cancel Actions

    init(
        _ title: String,
        subtitle: String,
        description: String? = nil,
        @ViewBuilder menu: @escaping () -> Content,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = Text(title)
        self.subtitle = Text(subtitle)
        self.description = description
        self.leadingView = { EmptyView() }
        self.menu = menu
        self.onSave = onSave
        self.onCancel = onCancel
    }

    // MARK: - Initializer: Text Inputs with Save/Cancel Actions

    init(
        title: Text,
        subtitle: Text,
        description: String? = nil,
        @ViewBuilder menu: @escaping () -> Content,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.leadingView = { EmptyView() }
        self.menu = menu
        self.onSave = onSave
        self.onCancel = onCancel
    }

    // MARK: - Initializer: String Inputs with only an Ok Action

    init(
        _ title: String,
        subtitle: String,
        description: String? = nil,
        @ViewBuilder menu: @escaping () -> Content
    ) {
        self.title = Text(title)
        self.subtitle = Text(subtitle)
        self.description = description
        self.leadingView = { EmptyView() }
        self.menu = menu
        self.onSave = nil
        self.onCancel = nil
    }

    // MARK: - Initializer: Text Inputs with only an Ok Action

    init(
        title: Text,
        subtitle: Text,
        description: String? = nil,
        @ViewBuilder menu: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.leadingView = { EmptyView() }
        self.menu = menu
        self.onSave = nil
        self.onCancel = nil
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

            if let onSave = onSave, let onCancel = onCancel {
                Button(L10n.save) {
                    onSave()
                    isSelected = false
                }
                Button(L10n.cancel, role: .cancel) {
                    onCancel()
                    isSelected = false
                }
            }
        } message: {
            if let description = description {
                Text(description)
            }
        }
    }
}
