//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ListRowMenu<Content: View, Subtitle: View>: View {

    @FocusState
    private var isFocused: Bool

    private let title: Text
    private let subtitle: Subtitle?
    private let content: () -> Content

    var body: some View {
        Menu(content: content) {
            buttonView
        }
        .menuStyle(.borderlessButton)
        .listRowInsets(.zero)
        .focused($isFocused)
    }

    @ViewBuilder
    private var buttonView: some View {
        HStack {
            title
                .foregroundStyle(isFocused ? .black : .white)
                .padding(.leading, 4)

            Spacer()

            if let subtitle {
                subtitle
                    .foregroundStyle(isFocused ? .black : .secondary)
                    .brightness(isFocused ? 0.4 : 0)
            }

            Image(systemName: "chevron.up.chevron.down")
                .font(.body.weight(.regular))
                .foregroundStyle(isFocused ? .black : .secondary)
                .brightness(isFocused ? 0.4 : 0)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .backport
        .glassEffect(
            .regular.tint(isFocused ? .white : nil),
            in: .capsule
        )
        .scaleEffect(x: isFocused ? 1.01 : 1.0, y: isFocused ? 1.05 : 1.0, anchor: .center)
        .animation(.easeInOut(duration: 0.125), value: isFocused)
        .listRowBackground(Color.clear)
    }
}

// MARK: - Initializers

// Base initializer
extension ListRowMenu where Subtitle == Text? {

    init(
        _ title: Text,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = nil
        self.content = content
    }

    init(
        _ title: Text,
        subtitle: Text?,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    init(
        _ title: Text,
        subtitle: String?,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle.map { Text($0) }
        self.content = content
    }

    init(
        _ title: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = Text(title)
        self.subtitle = nil
        self.content = content
    }

    init(
        _ title: String,
        subtitle: String?,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = Text(title)
        self.subtitle = subtitle.map { Text($0) }
        self.content = content
    }

    init(
        _ title: String,
        subtitle: Text?,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = Text(title)
        self.subtitle = subtitle
        self.content = content
    }
}

// Custom view subtitles
extension ListRowMenu {

    init(
        _ title: String,
        @ViewBuilder subtitle: @escaping () -> Subtitle,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = Text(title)
        self.subtitle = subtitle()
        self.content = content
    }

    init(
        _ title: Text,
        @ViewBuilder subtitle: @escaping () -> Subtitle,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle()
        self.content = content
    }
}

// Initialize from a CaseIterable Enum
extension ListRowMenu where Subtitle == Text, Content == AnyView {

    init<ItemType>(
        _ title: String,
        selection: Binding<ItemType>
    ) where ItemType: CaseIterable & Displayable & Hashable,
        ItemType.AllCases: RandomAccessCollection
    {
        self.title = Text(title)
        self.subtitle = Text(selection.wrappedValue.displayTitle)
        self.content = {
            Picker(title, selection: selection) {
                ForEach(Array(ItemType.allCases), id: \.self) { option in
                    Text(option.displayTitle).tag(option)
                }
            }
            .eraseToAnyView()
        }
    }
}

// Initialize from a SupportedCaseIterable Enum
extension ListRowMenu where Subtitle == Text, Content == AnyView {

    init<ItemType>(
        _ title: String,
        selection: Binding<ItemType>,
        onlySupported: Bool = false
    ) where ItemType: SupportedCaseIterable & Displayable & Hashable {
        let options = onlySupported ? Array(ItemType.supportedCases) : Array(ItemType.allCases)
        self.title = Text(title)
        self.subtitle = Text(selection.wrappedValue.displayTitle)
        self.content = {
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(option.displayTitle).tag(option)
                }
            }
            .eraseToAnyView()
        }
    }
}
