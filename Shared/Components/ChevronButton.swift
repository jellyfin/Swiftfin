//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: possibly consolidate with ListRow

struct ChevronButton<Label: View>: View {

    @Environment(\.isEditing)
    private var isEditing

    private let action: () -> Void
    private let isExternal: Bool
    private let label: Label

    var body: some View {
        Button(action: action) {
            HStack {

                label
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isEditing {
                    ListRowCheckbox()
                } else {
                    Image(systemName: isExternal ? "arrow.up.forward" : "chevron.right")
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .foregroundStyle(.primary, .secondary)
    }
}

extension ChevronButton {

    init(
        external: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.action = action
        self.isExternal = external
        self.label = label()
    }
}

extension ChevronButton where Label == Text {

    init(
        _ title: String,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            external: external,
            action: action
        ) {
            Text(title)
        }
    }
}

extension ChevronButton where Label == ChevronButtonValueContent<Text, Text> {

    init(
        _ title: String,
        content: String,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            title,
            content: Text(content),
            external: external,
            action: action
        )
    }

    init(
        _ title: String,
        content: Text,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            external: external,
            action: action
        ) {
            ChevronButtonValueContent {
                Text(title)
            } value: {
                content
            }
        }
    }
}

extension ChevronButton {

    init<Value: View>(
        _ title: String,
        external: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Value
    ) where Label == ChevronButtonValueContent<Text, Value> {
        self.init(
            external: external,
            action: action
        ) {
            ChevronButtonValueContent {
                Text(title)
            } value: {
                content()
            }
        }
    }
}

extension ChevronButton where Label == ChevronButtonLabelContent<SwiftUI.Label<Text, Image>> {

    init(
        _ title: String,
        systemName: String,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            external: external,
            action: action
        ) {
            ChevronButtonLabelContent {
                SwiftUI.Label { Text(title) } icon: { Image(systemName: systemName) }
            }
        }
    }

    init(
        _ title: String,
        image: ImageResource,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            external: external,
            action: action
        ) {
            ChevronButtonLabelContent {
                SwiftUI.Label { Text(title) } icon: { Image(image) }
            }
        }
    }
}

extension ChevronButton where Label == ChevronButtonValueContent<SwiftUI.Label<Text, Image>, Text> {

    init(
        _ title: String,
        content: String,
        systemName: String,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            title,
            content: Text(content),
            systemName: systemName,
            external: external,
            action: action
        )
    }

    init(
        _ title: String,
        content: Text,
        systemName: String,
        external: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            external: external,
            action: action
        ) {
            ChevronButtonValueContent {
                SwiftUI.Label { Text(title) } icon: { Image(systemName: systemName) }
            } value: {
                content
            }
        }
    }
}

struct ChevronButtonValueContent<Label: View, Value: View>: View {

    private let label: Label
    private let value: Value

    init(
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder value: @escaping () -> Value
    ) {
        self.label = label()
        self.value = value()
    }

    var body: some View {
        HStack {

            label
                .labelStyle(BoldIconLabelStyle())

            Spacer()

            value
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ChevronButtonLabelContent<Label: View>: View {

    private let label: Label

    init(@ViewBuilder label: @escaping () -> Label) {
        self.label = label()
    }

    var body: some View {
        label
            .labelStyle(BoldIconLabelStyle())
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
