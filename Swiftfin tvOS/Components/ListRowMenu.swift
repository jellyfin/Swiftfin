//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ListRowMenu<Content: View, Subtitle: View>: View {

    // MARK: - Focus State

    @FocusState
    private var isFocused: Bool

    // MARK: - Properties

    private let title: Text
    private let subtitle: Subtitle?
    private let content: () -> Content

    // MARK: - Body

    var body: some View {
        Menu(content: content) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isFocused ? Color.white : Color.clear)

                HStack {
                    title
                        .foregroundStyle(isFocused ? Color.black : Color.white)
                        .padding(.leading, 4)

                    Spacer()

                    if let subtitle {
                        subtitle
                            .foregroundStyle(isFocused ? Color.black : Color.secondary)
                            .brightness(isFocused ? 0.4 : 0)
                    }

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.body.weight(.regular))
                        .foregroundStyle(isFocused ? Color.black : Color.secondary)
                        .brightness(isFocused ? 0.4 : 0)
                }
                .padding(.horizontal)
            }
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.75), value: isFocused)
        }
        .menuStyle(.borderlessButton)
        .listRowInsets(.zero)
        .focused($isFocused)
    }
}

// MARK: - Initializers

// Base initializer
extension ListRowMenu where Subtitle == Text? {

    init(_ title: Text, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = nil
        self.content = content
    }

    init(_ title: Text, subtitle: Text?, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    init(_ title: Text, subtitle: String?, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle.map { Text($0) }
        self.content = content
    }

    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = Text(title)
        self.subtitle = nil
        self.content = content
    }

    init(_ title: String, subtitle: String?, @ViewBuilder content: @escaping () -> Content) {
        self.title = Text(title)
        self.subtitle = subtitle.map { Text($0) }
        self.content = content
    }

    init(_ title: String, subtitle: Text?, @ViewBuilder content: @escaping () -> Content) {
        self.title = Text(title)
        self.subtitle = subtitle
        self.content = content
    }
}

// Custom view subtitles
extension ListRowMenu {

    init(_ title: String, @ViewBuilder subtitle: @escaping () -> Subtitle, @ViewBuilder content: @escaping () -> Content) {
        self.title = Text(title)
        self.subtitle = subtitle()
        self.content = content
    }

    init(_ title: Text, @ViewBuilder subtitle: @escaping () -> Subtitle, @ViewBuilder content: @escaping () -> Content) {
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
