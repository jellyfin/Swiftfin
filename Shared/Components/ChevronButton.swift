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
        // On tvOS the default button style is focusable inside a `Form` but its Select press doesn't
        // fire the action. `.listRow` wires the press (borderless, like `ListRowMenu`) AND matches the
        // native row look — a flat row that fills white on focus — instead of a raised "glass" card.
        #if os(tvOS)
            .buttonStyle(.listRow)
        #endif
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

#if os(tvOS)

extension PrimitiveButtonStyle where Self == ListRowButtonStyle {

    /// tvOS list-row navigation button (see `ChevronButton`/`UserProfileRow`).
    static var listRow: ListRowButtonStyle {
        ListRowButtonStyle()
    }
}

/// A tvOS list-row button that fires reliably inside a `Form` — a plain `Button`'s Select press is
/// swallowed there — while matching the native `ListRowMenu` look: a flat, clear row that fills
/// WHITE on focus with black text (no raised "glass" card). `.borderless` captures the press without
/// drawing any card chrome, the same flat treatment `ListRowMenu`'s `Menu` uses.
struct ListRowButtonStyle: PrimitiveButtonStyle {

    @FocusState
    private var isFocused: Bool

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.trigger()
        } label: {
            configuration.label
                .foregroundStyle(
                    isFocused ? Color.black : Color.white,
                    isFocused ? Color.black.opacity(0.6) : Color.secondary
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.horizontal)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isFocused ? Color.white : Color.clear)
                }
                // The `.borderless` style auto-attaches a `.highlight` hover effect to the FIRST image
                // in the label (the trailing chevron) — that's what makes the arrow lift/scale wildly
                // on focus. Disable hover effects on the whole row so the ONLY focus cue is our flat
                // white-row highlight (matching `ListRowMenu`). See Apple's borderless docs.
                .hoverEffectDisabled()
                .scaleEffect(isFocused ? 1.04 : 1.0)
                .animation(.easeInOut(duration: 0.125), value: isFocused)
        }
        .buttonStyle(.borderless)
        .focused($isFocused)
        .listRowInsets(.zero)
    }
}

#endif
