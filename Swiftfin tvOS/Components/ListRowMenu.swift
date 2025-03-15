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
    private let subtitle: Text?
    private let content: Content

    // MARK: - Focus State

    @FocusState
    private var isFocused: Bool

    // MARK: - Initializer

    init(_ title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = Text(title)
        self.subtitle = subtitle == nil ? nil : Text(subtitle ?? L10n.unknown)
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        Menu {
            content
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isFocused ? .white : .clear)
                HStack {
                    title
                        .foregroundStyle(isFocused ? .black : .white)

                    Spacer()

                    subtitle
                        .foregroundStyle(isFocused ? .black : .secondary)
                        .brightness(isFocused ? 0.4 : 0)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.body.weight(.regular))
                        .foregroundStyle(isFocused ? .black : .secondary)
                        .brightness(isFocused ? 0.4 : 0)
                }
                .padding(.horizontal)
            }
        }
        .menuStyle(.borderlessButton)
        .listRowInsets(.zero)
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .shadow(color: isFocused ? .black.opacity(0.3) : .clear, radius: isFocused ? 5 : 0)
        .animation(.spring(response: 0.15, dampingFraction: 0.85), value: isFocused)
    }
}
