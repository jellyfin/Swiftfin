//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ListRowMenu<Content: View, Subtitle: View>: View {

    private let title: Text
    private let subtitle: Subtitle?
    private let content: () -> Content

    var body: some View {
        Menu(content: content) {
            HStack {
                title
                    .foregroundStyle(.primary)

                Spacer()

                if let subtitle {
                    subtitle
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "chevron.up.chevron.down")
                    .font(.body.weight(.regular))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, -8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .listRowInsets(.zero)
        .listRowBackground(Color.clear)
    }
}

// MARK: - Initializers

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

// MARK: - Custom View Subtitles

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

// MARK: - CaseIterable Enum Initializer

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
