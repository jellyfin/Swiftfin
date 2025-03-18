//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct ActionMenu<Content: View>: View {

        // MARK: - Focus State

        @FocusState
        private var isFocused: Bool

        // MARK: - Properties

        private let title: String
        private let icon: String
        private let imageRotation: Angle
        private let content: () -> Content

        // MARK: - Initializers

        init(
            _ title: String,
            icon: String,
            imageRotation: Angle = .degrees(0),
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.title = title
            self.icon = icon
            self.imageRotation = imageRotation
            self.content = content
        }

        // MARK: - Body

        var body: some View {
            Menu {
                content()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isFocused ? Color.white : Color.white.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.clear, lineWidth: 2)
                        )

                    Label(title, systemImage: icon)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                        .labelStyle(.iconOnly)
                        .rotationEffect(imageRotation)
                }
                .accessibilityLabel(title)
            }
            .padding(0)
            .focused($isFocused)
            .scaleEffect(isFocused ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .menuStyle(.borderlessButton)
        }
    }
}
