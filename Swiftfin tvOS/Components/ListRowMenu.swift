//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ListRowMenu<Content: View>: View {

    // MARK: - Properties

    private let title: Text
    private let subtitle: AnyView?
    private let content: Content

    // MARK: - Focus State

    @FocusState
    private var isFocused: Bool

    // MARK: - Main Initializer

    private init(
        title: Text,
        subtitle: AnyView? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        Menu {
            content
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isFocused ? Color.white : Color.clear)
                HStack {
                    title
                        .foregroundStyle(isFocused ? Color.black : Color.white)

                    Spacer()

                    if let subtitle = subtitle {
                        subtitle
                            .foregroundStyle(isFocused ? Color.black : Color.secondary)
                            .brightness(isFocused ? 0.4 : 0)
                    }

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.body.weight(.regular))
                        .foregroundColor(isFocused ? Color.black : Color.secondary)
                        .brightness(isFocused ? 0.4 : 0)
                }
                .padding(.horizontal)
            }
            .scaleEffect(isFocused ? 1.05 : 1.0, anchor: .center)
            .animation(.spring(response: 0.15, dampingFraction: 0.75), value: isFocused)
        }
        .menuStyle(.borderlessButton)
        .listRowInsets(.zero)
        .focused($isFocused)
    }
}

// MARK: - Initializers

extension ListRowMenu {
    // String title, no subtitle
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.init(
            title: Text(title),
            content: content
        )
    }

    // String title, string subtitle
    init(_ title: String, subtitle: String?, @ViewBuilder content: () -> Content) {
        self.init(
            title: Text(title),
            subtitle: subtitle == nil ? nil : AnyView(Text(subtitle ?? "Unknown")),
            content: content
        )
    }

    // Text title, no subtitle
    init(_ title: Text, @ViewBuilder content: () -> Content) {
        self.init(
            title: title,
            content: content
        )
    }

    // Text title, string subtitle
    init(title: Text, subtitle: String?, @ViewBuilder content: () -> Content) {
        self.init(
            title: title,
            subtitle: subtitle == nil ? nil : AnyView(Text(subtitle ?? "Unknown")),
            content: content
        )
    }

    // String title, Text subtitle
    init(_ title: String, subtitleText: Text?, @ViewBuilder content: () -> Content) {
        self.init(
            title: Text(title),
            subtitle: subtitleText == nil ? nil : AnyView(subtitleText!),
            content: content
        )
    }

    // Text title, Text subtitle
    init(title: Text, subtitleText: Text?, @ViewBuilder content: () -> Content) {
        self.init(
            title: title,
            subtitle: subtitleText == nil ? nil : AnyView(subtitleText!),
            content: content
        )
    }

    // String title, custom view subtitle
    init<S: View>(_ title: String, subtitleView: S, @ViewBuilder content: () -> Content) {
        self.init(
            title: Text(title),
            subtitle: AnyView(subtitleView),
            content: content
        )
    }

    // Text title, custom view subtitle
    init<S: View>(title: Text, subtitleView: S, @ViewBuilder content: () -> Content) {
        self.init(
            title: title,
            subtitle: AnyView(subtitleView),
            content: content
        )
    }
}
