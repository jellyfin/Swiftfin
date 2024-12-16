//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: find better name

struct ChevronAlertButton<Content>: View where Content: View {

    // MARK: - Dialog State

    @State
    private var isSelected = false

    // MARK: - Chevron Alert Variables

    private let title: String
    private let subtitle: Text?
    private let description: String?
    private let orientaiton: FullScreenMenu.Orientation

    // MARK: - Chevron Alert Content

    private let content: () -> Content

    // MARK: - Chevron Alert Actions

    private let onSave: (() -> Void)?
    private let onCancel: (() -> Void)?

    // MARK: - Body

    var body: some View {
        ChevronButton(title, subtitle: subtitle)
            .onSelect {
                isSelected = true
            }
            .fullScreenMenu(
                isPresented: $isSelected,
                title: title,
                subtitle: description,
                orientation: orientaiton
            ) {
                content()
            } footer: {
                footerView
            }
    }

    @ViewBuilder
    private var footerView: Content {
        HStack(spacing: 24) {
            if let onCancel {
                Button(L10n.cancel, role: .cancel) {
                    onCancel()
                    isSelected = false
                }
            }

            if let onSave {
                Button(L10n.save) {
                    onSave()
                    isSelected = false
                }
            }
        } as! Content
    }
}

extension ChevronAlertButton {

    // MARK: - Initializer

    init(
        _ title: String,
        subtitle: String? = nil,
        description: String? = nil,
        orientaiton: FullScreenMenu.Orientation = .center,
        @ViewBuilder content: @escaping () -> Content,
        onSave: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            subtitle: subtitle != nil ? Text(subtitle!) : nil,
            description: description,
            orientaiton: orientaiton,
            content: content,
            onSave: onSave,
            onCancel: onCancel
        )
    }

    // MARK: - Initializer: Text Inputs with Save/Cancel Actions

    init(
        _ title: String,
        subtitle: Text?,
        description: String? = nil,
        orientaiton: FullScreenMenu.Orientation = .center,
        @ViewBuilder content: @escaping () -> Content,
        onSave: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            description: description,
            orientaiton: orientaiton,
            content: content,
            onSave: onSave,
            onCancel: onCancel
        )
    }
}
