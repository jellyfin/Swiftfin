//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: find better name

struct ChevronAlertButton<Content>: View where Content: View {

    @State
    private var isSelected = false

    private let content: () -> Content
    private let description: String?
    private let onCancel: (() -> Void)?
    private let onSave: (() -> Void)?
    private let subtitle: Text?
    private let title: String

    // MARK: - Body

    var body: some View {
        ChevronButton(title, subtitle: subtitle)
            .onSelect {
                isSelected = true
            }
            .alert(title, isPresented: $isSelected) {

                content()

                if let onSave {
                    Button(L10n.save) {
                        onSave()
                        isSelected = false
                    }
                }

                if let onCancel {
                    Button(L10n.cancel, role: .cancel) {
                        onCancel()
                        isSelected = false
                    }
                }
            } message: {
                if let description {
                    Text(description)
                }
            }
    }
}

extension ChevronAlertButton {

    init(
        _ title: String,
        subtitle: String?,
        description: String? = nil,
        @ViewBuilder content: @escaping () -> Content,
        onSave: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.init(
            content: content,
            description: description,
            onCancel: onCancel,
            onSave: onSave,
            subtitle: subtitle != nil ? Text(subtitle!) : nil,
            title: title
        )
    }

    // MARK: - Initializer: Text Inputs with Save/Cancel Actions

    init(
        _ title: String,
        subtitle: Text?,
        description: String? = nil,
        @ViewBuilder content: @escaping () -> Content,
        onSave: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.init(
            content: content,
            description: description,
            onCancel: onCancel,
            onSave: onSave,
            subtitle: subtitle,
            title: title
        )
    }
}
