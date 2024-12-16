//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FullScreenMenu<Content: View>: View {

    // MARK: - Menu Variables

    private var title: String?
    private var subtitle: String?
    private let orientation: Alignment

    // MARK: - Menu Contents

    private let content: () -> Content

    // MARK: - Initializer

    init(
        _ title: String? = nil,
        subtitle: String? = nil,
        orientation: Alignment = .trailing,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.orientation = orientation
        self.content = content
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: orientation) {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            contentView
                .padding(0)
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        VStack {
            VStack(spacing: 4) {
                if let title {
                    Text(title)
                        .font(.headline)
                }
                if let subtitle {
                    Text(subtitle)
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }

            content()
                .eraseToAnyView()
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
        }
        .padding(32)
        .background {
            RoundedRectangle(cornerRadius: 30)
                .fill(Material.regular)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.black.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .shadow(radius: 50)
        .frame(
            width: UIScreen.main.bounds.width / 3,
            height: UIScreen.main.bounds.height * 0.9
        )
    }
}
