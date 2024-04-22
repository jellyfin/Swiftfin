//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: is the background color setting really the best way?

struct SystemImageContentView: View {

    @State
    private var contentSize: CGSize = .zero
    @State
    private var labelSize: CGSize = .zero

    private var backgroundColor: Color
    private var heightRatio: CGFloat
    private let systemName: String
    private let title: String?
    private var widthRatio: CGFloat

    init(title: String? = nil, systemName: String?) {
        self.backgroundColor = Color.secondarySystemFill
        self.heightRatio = 3
        self.systemName = systemName ?? "circle"
        self.title = title
        self.widthRatio = 3.5
    }

    private var imageView: some View {
        Image(systemName: systemName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.secondary)
            .accessibilityHidden(true)
            .frame(width: contentSize.width / widthRatio, height: contentSize.height / heightRatio)
    }

    @ViewBuilder
    private var label: some View {
        if let title {
            Text(title)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .font(.footnote.weight(.regular))
                .foregroundColor(.secondary)
                .trackingSize($labelSize)
        }
    }

    var body: some View {
        ZStack {
            backgroundColor
                .opacity(0.5)

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

    func imageFrameRatio(width: CGFloat = 3.5, height: CGFloat = 3) -> Self {
        copy(modifying: \.heightRatio, with: height)
            .copy(modifying: \.widthRatio, with: width)
    }
}
