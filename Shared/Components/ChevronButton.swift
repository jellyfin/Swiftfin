//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: Remove alert and just be a Button
// TODO: change "subtitle" to "content"

struct ChevronButton<_Label: View, _Content: View>: View {

    private let isExternal: Bool
    private let labeledContent: LabeledContent<_Label, _Content>

    private let innerContent: (LabeledContent<_Label, _Content>) -> AnyView

    var body: some View {
        innerContent(labeledContent)
            .labeledContentStyle(ChevronButtonLabeledContentStyle(isExternal: isExternal))
            .eraseToAnyView()
    }
}

extension ChevronButton {

    private init(
        labeledContent: LabeledContent<_Label, _Content>,
        external: Bool = false,
        @ViewBuilder innerContent: @escaping (LabeledContent<_Label, _Content>) -> some View
    ) {
        self.isExternal = external
        self.labeledContent = labeledContent
        self.innerContent = { labeledContent in
            innerContent(labeledContent)
                .eraseToAnyView()
        }
    }

    private init(
        labeledContent: LabeledContent<_Label, _Content>,
        external: Bool = false,
        action: @escaping () -> Void,
        isTitleOnly: Bool = false
    ) {
        self.init(
            labeledContent: labeledContent,
            external: external
        ) { labeledContent in
            ButtonContentView(
                label: labeledContent,
                action: action,
                isTitleOnly: isTitleOnly
            )
        }
    }

    @available(*, deprecated, message: "Use Engine.StateAdapter with an inline alert instead")
    private init(
        labeledContent: LabeledContent<_Label, _Content>,
        alertTitle: String,
        description: String?,
        @ViewBuilder content: @escaping () -> some View,
        onSave: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.init(labeledContent: labeledContent) { labeledContent in
            AlertContentView(
                alertTitle: alertTitle,
                content: content,
                description: description,
                label: labeledContent,
                onCancel: onCancel,
                onSave: onSave
            )
        }
    }

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
        let isTitleOnly: Bool

        var body: some View {
            Button(action: action) {
                if isTitleOnly {
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
        external: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> LabeledContent<_Label, _Content>
    ) {
        self.init(
            labeledContent: label(),
            external: external,
            action: action
        )
    }

    @available(*, deprecated, message: "Use `init(external:action:label:)` instead")
    init<Icon: View>(
        _ title: String,
        external: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder icon: @escaping () -> Icon,
        @ViewBuilder subtitle: @escaping () -> _Content
    ) where _Label == Label<Text, Icon> {
        self.init(
            labeledContent: LabeledContent {
                subtitle()
            } label: {
                Label(title: { Text(title) }, icon: icon)
            },
            external: external,
            action: action,
            isTitleOnly: Icon.self == EmptyView.self
        )
    }
}

extension ChevronButton where _Label == Label<Text, EmptyView>, _Content == Text {

    init(
        _ title: String,
        subtitle: String,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            title,
            external: external,
            action: action,
            icon: { EmptyView() },
            subtitle: { Text(subtitle) }
        )
    }

    init(
        _ title: String,
        subtitle: Text,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            title,
            external: external,
            action: action,
            icon: { EmptyView() },
            subtitle: { subtitle }
        )
    }

    @available(*, deprecated, message: "Use Engine.StateAdapter with an inline alert instead")
    init(
        _ title: String,
        subtitle: String? = nil,
        description: String?,
        @ViewBuilder content: @escaping () -> some View,
        onSave: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.init(
            labeledContent: LabeledContent {
                Text(subtitle ?? "")
            } label: {
                Label(title: { Text(title) }, icon: { EmptyView() })
            },
            alertTitle: title,
            description: description,
            content: content,
            onSave: onSave,
            onCancel: onCancel
        )
    }

    @available(*, deprecated, message: "Use Engine.StateAdapter with an inline alert instead")
    init(
        _ title: String,
        subtitle: Text? = nil,
        description: String?,
        @ViewBuilder content: @escaping () -> some View,
        onSave: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.init(
            labeledContent: LabeledContent {
                subtitle ?? Text("")
            } label: {
                Label(title: { Text(title) }, icon: { EmptyView() })
            },
            alertTitle: title,
            description: description,
            content: content,
            onSave: onSave,
            onCancel: onCancel
        )
    }
}

extension ChevronButton where _Label == Label<Text, EmptyView>, _Content == EmptyView {

    init(
        _ title: String,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            title,
            external: external,
            action: action,
            icon: { EmptyView() },
            subtitle: { EmptyView() }
        )
    }
}

extension ChevronButton where _Label == Label<Text, Image>, _Content == Text {

    // systemName

    init(
        _ title: String,
        subtitle: String,
        systemName: String,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            title,
            external: external,
            action: action,
            icon: { Image(systemName: systemName) },
            subtitle: { Text(subtitle) }
        )
    }

    init(
        _ title: String,
        subtitle: Text,
        systemName: String,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            title,
            external: external,
            action: action,
            icon: { Image(systemName: systemName) },
            subtitle: { subtitle }
        )
    }
}

extension ChevronButton where _Label == Label<Text, Image>, _Content == EmptyView {

    // systemName

    init(
        _ title: String,
        systemName: String,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            title,
            external: external,
            action: action,
            icon: { Image(systemName: systemName) },
            subtitle: { EmptyView() }
        )
    }

    // ImageResource

    init(
        _ title: String,
        image: ImageResource,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            title,
            external: external,
            action: action,
            icon: { Image(image) },
            subtitle: { EmptyView() }
        )
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

extension LabelStyle where Self == BoldIconLabelStyle {
    static var boldIcon: BoldIconLabelStyle {
        BoldIconLabelStyle()
    }
}

struct BoldIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        Label {
            configuration.title
        } icon: {
            configuration.icon
                .fontWeight(.bold)
        }
    }
}
