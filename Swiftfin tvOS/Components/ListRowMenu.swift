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
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isFocused ? Color.white : Color.clear)
            )
            .scaleEffect(isFocused ? 1.04 : 1.0)
            .animation(.easeInOut(duration: 0.125), value: isFocused)
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

    // multi-selection from a CaseIterable Enum
    init<ItemType>(
        _ title: String,
        selection: Binding<[ItemType]>
    ) where ItemType: CaseIterable & Displayable & Hashable,
        ItemType.AllCases: RandomAccessCollection
    {
        let selectedCount = selection.wrappedValue.count
        let subtitleText: String
        if selectedCount == 0 {
            subtitleText = L10n.none
        } else if selectedCount == 1 {
            subtitleText = selection.wrappedValue.first?.displayTitle ?? L10n.none
        } else {
            subtitleText = "\(selectedCount) selected"
        }

        self.title = Text(title)
        self.subtitle = Text(subtitleText)
        self.content = {
            ForEach(Array(ItemType.allCases), id: \.self) { option in
                Button(action: {
                    var currentSelection = selection.wrappedValue
                    if currentSelection.contains(option) {
                        currentSelection.removeAll { $0 == option }
                    } else {
                        currentSelection.append(option)
                    }
                    selection.wrappedValue = currentSelection
                }) {
                    HStack {
                        Text(option.displayTitle)
                        Spacer()
                        if selection.wrappedValue.contains(option) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .eraseToAnyView()
        }
    }

    // multi-selection with dynamic items (for non-CaseIterable types)
    init<Item: Hashable & Displayable>(
        _ title: String,
        subtitle: String,
        items: [Item],
        selection: Binding<[Item]>
    ) {
        self.title = Text(title)
        self.subtitle = Text(subtitle)
        self.content = {
            ForEach(items, id: \.hashValue) { item in
                Button(action: {
                    var currentSelection = selection.wrappedValue
                    if currentSelection.contains(item) {
                        currentSelection.removeAll { $0.hashValue == item.hashValue }
                    } else {
                        currentSelection.append(item)
                    }
                    selection.wrappedValue = currentSelection
                }) {
                    HStack {
                        Text(item.displayTitle)
                        Spacer()
                        if selection.wrappedValue.contains(item) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .eraseToAnyView()
        }
    }
}
