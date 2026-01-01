//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ChevronButton<Icon: View, Subtitle: View>: View {

    private let isExternal: Bool
    private let subtitle: Subtitle
    private let label: Label<Text, Icon>

    private let innerContent: (LabeledContent<Label<Text, Icon>, Subtitle>) -> any View

    var body: some View {
        innerContent(
            LabeledContent {
                subtitle
            } label: {
                label
            }
        )
        .labeledContentStyle(ChevronButtonLabeledContentStyle(isExternal: isExternal))
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
                if Icon.self == EmptyView.self {
                    label
                        .labelStyle(.titleOnly)
                } else {
                    label
                }
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
        self.isExternal = external
        self.label = Label(title: { Text(title) }, icon: icon)
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
        self.isExternal = external
        self.label = Label(title: { title }, icon: icon)
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
        self.isExternal = external
        self.label = Label(title: { Text(title) }, icon: { EmptyView() })
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
        self.isExternal = external
        self.label = Label(title: { Text(title) }, icon: { EmptyView() })
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
        self.isExternal = external
        self.label = Label(title: { Text(title) }, icon: { EmptyView() })
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
        self.isExternal = external
        self.label = Label(title, systemImage: systemName)
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
        self.isExternal = external
        self.label = Label(title, systemImage: systemName)
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
        self.isExternal = external
        self.label = Label(title: { Text(title) }, icon: { Image(image) })
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
        self.isExternal = external
        self.label = Label(title: { Text(title) }, icon: { Image(image) })
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
        self.isExternal = external
        self.label = Label(title, systemImage: systemName)
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
        self.isExternal = external
        self.label = Label(title: { Text(title) }, icon: { Image(image) })
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
        description: String?,
        @ViewBuilder content: @escaping () -> Content,
        onSave: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.isExternal = false
        self.label = Label(title: { Text(title) }, icon: { EmptyView() })
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
        description: String?,
        @ViewBuilder content: @escaping () -> Content,
        onSave: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.isExternal = false
        self.label = Label(title: { Text(title) }, icon: { EmptyView() })
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

private struct ChevronButtonLabeledContentStyle: LabeledContentStyle {

    let isExternal: Bool

    func makeBody(configuration: Configuration) -> some View {
        HStack {

            configuration.label
                .labelStyle(BoldIconLabelStyle())

            Spacer()

            configuration.content
                .foregroundStyle(.secondary)

            Image(systemName: isExternal ? "arrow.up.forward" : "chevron.right")
                .font(.body)
                .fontWeight(.regular)
                .foregroundStyle(.secondary)
        }
    }
}

private struct BoldIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        Label {
            configuration.title
        } icon: {
            configuration.icon
                .fontWeight(.bold)
        }
    }
}
