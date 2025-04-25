//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ChevronButton<Icon: View, Subtitle: View>: View {

    private let icon: Icon
    private let isExternal: Bool
    private let title: Text
    private let subtitle: Subtitle

    private let innerContent: (AnyView) -> any View

    @ViewBuilder
    private var label: some View {
        HStack {

            icon
                .font(.body.weight(.bold))

            title

            Spacer()

            subtitle
                .foregroundStyle(.secondary)

            Image(systemName: isExternal ? "arrow.up.forward" : "chevron.right")
                .font(.body.weight(.regular))
                .foregroundStyle(.secondary)
        }
    }

    var body: some View {
        innerContent(label.eraseToAnyView())
            .eraseToAnyView()
    }
}

extension ChevronButton {

    private struct AlertContentView<Content: View, Label: View>: View {

        @State
        private var isPresented: Bool = false

        let alertTitle: String
        let content: () -> Content
        let description: String?
        let label: Label
        let onCancel: (() -> Void)?
        let onSave: (() -> Void)?

        var body: some View {
            Button {
                isPresented = true
            } label: {
                label
            }
            .foregroundStyle(.primary, .secondary)
            .alert(alertTitle, isPresented: $isPresented) {

                content()

                if let onSave {
                    Button(L10n.save) {
                        onSave()
                        isPresented = false
                    }
                }

                if let onCancel {
                    Button(L10n.cancel, role: .cancel) {
                        onCancel()
                        isPresented = false
                    }
                }
            } message: {
                if let description {
                    Text(description)
                }
            }
        }
    }

    private struct ButtonContentView<Label: View>: View {

        let label: Label
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                label
            }
            .foregroundStyle(.primary, .secondary)
        }
    }
}

extension ChevronButton {

    init(
        _ title: String,
        external: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder icon: @escaping () -> Icon,
        @ViewBuilder subtitle: @escaping () -> Subtitle
    ) {
        self.icon = icon()
        self.isExternal = external
        self.title = Text(title)
        self.subtitle = subtitle()
        self.innerContent = { label in
            ButtonContentView(
                label: label,
                action: action
            )
        }
    }

    init(
        _ title: Text,
        external: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder icon: @escaping () -> Icon,
        @ViewBuilder subtitle: @escaping () -> Subtitle
    ) {
        self.icon = icon()
        self.isExternal = external
        self.title = title
        self.subtitle = subtitle()
        self.innerContent = { label in
            ButtonContentView(
                label: label,
                action: action
            )
        }
    }
}

extension ChevronButton where Icon == EmptyView, Subtitle == Text {

    init(
        _ title: String,
        subtitle: String,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = EmptyView()
        self.isExternal = external
        self.title = Text(title)
        self.subtitle = Text(subtitle)
        self.innerContent = { label in
            ButtonContentView(
                label: label,
                action: action
            )
        }
    }

    init(
        _ title: String,
        subtitle: Text,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = EmptyView()
        self.isExternal = external
        self.title = Text(title)
        self.subtitle = subtitle
        self.innerContent = { label in
            ButtonContentView(
                label: label,
                action: action
            )
        }
    }
}

extension ChevronButton where Icon == EmptyView, Subtitle == EmptyView {

    init(
        _ title: String,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = EmptyView()
        self.isExternal = external
        self.title = Text(title)
        self.subtitle = EmptyView()
        self.innerContent = { label in
            ButtonContentView(
                label: label,
                action: action
            )
        }
    }
}

extension ChevronButton where Icon == Image, Subtitle == Text {

    // systemName

    init(
        _ title: String,
        subtitle: String,
        systemName: String,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = Image(systemName: systemName)
        self.isExternal = external
        self.title = Text(title)
        self.subtitle = Text(subtitle)
        self.innerContent = { label in
            ButtonContentView(
                label: label,
                action: action
            )
        }
    }

    init(
        _ title: String,
        subtitle: Text,
        systemName: String,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = Image(systemName: systemName)
        self.isExternal = external
        self.title = Text(title)
        self.subtitle = subtitle
        self.innerContent = { label in
            ButtonContentView(
                label: label,
                action: action
            )
        }
    }

    // ImageResource

    init(
        _ title: String,
        subtitle: String,
        image: ImageResource,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = Image(image)
        self.isExternal = external
        self.title = Text(title)
        self.subtitle = Text(subtitle)
        self.innerContent = { label in
            ButtonContentView(
                label: label,
                action: action
            )
        }
    }

    init(
        _ title: String,
        subtitle: Text,
        image: ImageResource,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = Image(image)
        self.isExternal = external
        self.title = Text(title)
        self.subtitle = subtitle
        self.innerContent = { label in
            ButtonContentView(
                label: label,
                action: action
            )
        }
    }
}

extension ChevronButton where Icon == Image, Subtitle == EmptyView {

    // systemName

    init(
        _ title: String,
        systemName: String,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = Image(systemName: systemName)
        self.isExternal = external
        self.title = Text(title)
        self.subtitle = EmptyView()
        self.innerContent = { label in
            ButtonContentView(
                label: label,
                action: action
            )
        }
    }

    // ImageResource

    init(
        _ title: String,
        image: ImageResource,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = Image(image)
        self.isExternal = external
        self.title = Text(title)
        self.subtitle = EmptyView()
        self.innerContent = { label in
            ButtonContentView(
                label: label,
                action: action
            )
        }
    }
}

extension ChevronButton where Icon == EmptyView, Subtitle == Text {

    init<Content: View>(
        _ title: String,
        subtitle: String? = nil,
        description: String? = nil,
        @ViewBuilder content: @escaping () -> Content,
        onSave: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.icon = EmptyView()
        self.isExternal = false
        self.title = Text(title)
        self.subtitle = Text(subtitle ?? "")
        self.innerContent = { label in
            AlertContentView(
                alertTitle: title,
                content: content,
                description: description,
                label: label,
                onCancel: onCancel,
                onSave: onSave
            )
        }
    }

    init<Content: View>(
        _ title: String,
        subtitle: Text? = nil,
        description: String? = nil,
        @ViewBuilder content: @escaping () -> Content,
        onSave: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.icon = EmptyView()
        self.isExternal = false
        self.title = Text(title)
        self.subtitle = subtitle ?? Text("")
        self.innerContent = { label in
            AlertContentView(
                alertTitle: title,
                content: content,
                description: description,
                label: label,
                onCancel: onCancel,
                onSave: onSave
            )
        }
    }
}
