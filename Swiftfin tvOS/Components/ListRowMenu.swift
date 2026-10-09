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

    @ViewBuilder
    private var buttonView: some View {
        if UIDevice.supportsLiquidGlass {
            glassBody
        } else {
            legacyBody
        }
    }

    @ViewBuilder
    private var labelView: some View {
        HStack {
            title
                .foregroundStyle(isFocused ? .black : .white)
                .padding(.leading, 4)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let subtitle {
                subtitle
                    .foregroundStyle(isFocused ? .black : .secondary)
                    .brightness(isFocused ? 0.4 : 0)
            }

            Image(systemName: "chevron.up.chevron.down")
                .font(.body)
                .fontWeight(.regular)
                .foregroundStyle(isFocused ? .black : .secondary)
                .brightness(isFocused ? 0.4 : 0)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var glassBody: some View {
        labelView
            .glassEffect(
                .regular.tint(isFocused ? .white : nil),
                in: .capsule
            )
            .scaleEffect(x: isFocused ? 1.01 : 1.0, y: isFocused ? 1.05 : 1.0, anchor: .center)
            .animation(.easeInOut(duration: 0.125), value: isFocused)
            .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private var legacyBody: some View {
        labelView
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 12.5)
                        .fill(isFocused ? Color.white : Color.clear)

                    if isFocused {
                        RoundedRectangle(cornerRadius: 12.5)
                            .fill(Color.white.opacity(0.8))
                            .scaleEffect(x: 1, y: 1.1, anchor: .center)
                    }
                }
            }
            .scaleEffect(x: isFocused ? 1.01 : 1.0, y: isFocused ? 1.05 : 1.0, anchor: .center)
            .animation(.easeInOut(duration: 0.125), value: isFocused)
            .listRowBackground(Color.clear)
    }

    var body: some View {
        Menu(content: content) {
            buttonView
        }
        .menuStyle(.borderlessButton)
        .listRowInsets(.zero)
        .focused($isFocused)
    }
}

// MARK: - Initializers

extension ListRowMenu where Subtitle == Text? {

    init(
        _ title: some WithText,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title.textBody
        self.subtitle = nil
        self.content = content
    }

    init(
        _ title: some WithText,
        subtitle: (some WithText)?,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title.textBody
        self.subtitle = subtitle?.textBody
        self.content = content
    }
}

extension ListRowMenu {

    init(
        _ title: some WithText,
        @ViewBuilder subtitle: @escaping () -> Subtitle,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title.textBody
        self.subtitle = subtitle()
        self.content = content
    }
}

extension ListRowMenu where Subtitle == Text, Content == AnyView {

    init<SelectionValue>(
        _ title: some WithText,
        selection: Binding<SelectionValue>
    ) where SelectionValue: CaseIterable & Displayable & Hashable,
        SelectionValue.AllCases: RandomAccessCollection
    {
        self.title = title.textBody
        self.subtitle = Text(selection.wrappedValue.displayTitle)
        self.content = {
            Picker(selection: selection) {
                _CaseIterablePickerContent<SelectionValue>()
            } label: {
                title.textBody
            }
            .eraseToAnyView()
        }
    }
}
