//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct RelativeSystemImageView: View {

    @State
    private var contentSize: CGSize = .zero

    private let systemName: String
    private let ratio: CGFloat

    init(
        systemName: String,
        ratio: CGFloat = 0.5
    ) {
        self.systemName = systemName
        self.ratio = ratio
    }

    var body: some View {
        AlternateLayoutView {
            Color.clear
                .trackingSize($contentSize)
        } content: {
            Image(systemName: systemName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .accessibilityHidden(true)
                .frame(width: contentSize.width * ratio, height: contentSize.height * ratio)
        }
    }
}

// TODO: is the background color setting really the best way?

struct SystemImageContentView: View {

    @State
    private var contentSize: CGSize = .zero
    @State
    private var labelSize: CGSize = .zero

    private var backgroundColor: Color
    private var ratio: CGFloat
    private let systemName: String
    private let title: String?

    init(title: String? = nil, systemName: String?, ratio: CGFloat = 0.33) {
        self.backgroundColor = Color.secondarySystemFill
        self.ratio = ratio
        self.systemName = systemName ?? "circle"
        self.title = title
    }

    private var imageView: some View {
        RelativeSystemImageView(
            systemName: systemName,
            ratio: ratio
        )
        .foregroundColor(.secondary)
    }

    @ViewBuilder
    private var label: some View {
        if let title {
            Text(title)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .font(.footnote.weight(.regular))
                .foregroundStyle(.secondary)
                .trackingSize($labelSize)
        }
    }

    var body: some View {
        ZStack {
            backgroundColor

            imageView
                .frame(width: contentSize.width)
                .overlay(alignment: .bottom) {
                    label
                        .padding(.horizontal, 4)
                        .offset(y: labelSize.height)
                }
        }
        .trackingSize($contentSize)
    }
}

extension SystemImageContentView {

    func background(color: Color = Color.secondarySystemFill) -> Self {
        copy(modifying: \.backgroundColor, with: color)
    }
}
