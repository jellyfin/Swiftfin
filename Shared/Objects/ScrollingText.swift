//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

public struct ScrollingText: View {

    // MARK: - Text Variables

    private let text: String
    private var font: UIFont?

    // MARK: - Scrolling Variables

    private let leftFade: CGFloat
    private let rightFade: CGFloat
    private let startDelay: Double

    // MARK: - Alignment

    private let alignment: Alignment

    // MARK: - State Variables

    @State
    private var animate = false
    private var isCompact = false

    // MARK: - Body

    public var body: some View {
        let currentFont = font ?? UIFont.preferredFont(forTextStyle: .body)
        let stringWidth = text.widthOfString(usingFont: currentFont)
        let stringHeight = text.heightOfString(usingFont: currentFont)

        // Create our animations
        let animation = Animation
            .linear(duration: Double(stringWidth) / 30)
            .delay(startDelay)
            .repeatForever(autoreverses: false)

        let nullAnimation = Animation.linear(duration: 0)

        GeometryReader { geo in
            // Decide if scrolling is needed
            let needsScrolling = (stringWidth > geo.size.width)

            ZStack {
                if needsScrolling {

                    // MARK: Scrolling logic

                    makeScrollingTexts(
                        stringWidth: stringWidth,
                        stringHeight: stringHeight,
                        geoWidth: geo.size.width,
                        animation: animation,
                        nullAnimation: nullAnimation,
                        currentFont: currentFont
                    )
                    // force left alignment when scrolling
                    .frame(
                            minWidth: 0,
                            maxWidth: .infinity,
                            minHeight: 0,
                            maxHeight: .infinity,
                            alignment: .topLeading
                        )
                        .offset(x: leftFade)
                        .mask(
                            fadeMask(
                                leftFade: leftFade,
                                rightFade: rightFade
                            )
                        )
                        .frame(width: geo.size.width + leftFade)
                        .offset(x: -leftFade)
                } else {
                    // MARK: - Non-scrolling version

                    Text(text)
                        .foregroundStyle(.primary)
                        .font(font == nil ? nil : .init(currentFont))
                        .onChange(of: text) { _ in
                            self.animate = false
                        }
                        .frame(
                            minWidth: 0,
                            maxWidth: .infinity,
                            minHeight: 0,
                            maxHeight: .infinity,
                            alignment: alignment
                        )
                }
            }
            .onAppear {
                // Trigger scrolling if needed
                self.animate = needsScrolling
            }
            .onChange(of: text) { newValue in
                let newStringWidth = newValue.widthOfString(usingFont: currentFont)
                if newStringWidth > geo.size.width {
                    // Stop the old animation first
                    self.animate = false

                    // Kick off a new animation on the next runloop
                    DispatchQueue.main.async {
                        self.animate = true
                    }
                } else {
                    self.animate = false
                }
            }
        }
        .frame(height: stringHeight)
        .frame(maxWidth: isCompact ? stringWidth : nil)
        .onDisappear {
            self.animate = false
        }
    }

    // MARK: - Scrolling pair of texts

    @ViewBuilder
    private func makeScrollingTexts(
        stringWidth: CGFloat,
        stringHeight: CGFloat,
        geoWidth: CGFloat,
        animation: Animation,
        nullAnimation: Animation,
        currentFont: UIFont
    ) -> some View {
        Group {
            Text(text)
                .lineLimit(1)
                .font(font == nil ? nil : .init(currentFont))
                .offset(x: animate ? -stringWidth - stringHeight * 2 : 0)
                .animation(animate ? animation : nullAnimation, value: animate)
                .fixedSize(horizontal: true, vertical: false)

            Text(text)
                .lineLimit(1)
                .font(font == nil ? nil : .init(currentFont))
                .offset(x: animate ? 0 : stringWidth + stringHeight * 2)
                .animation(animate ? animation : nullAnimation, value: animate)
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    // MARK: - Fade mask

    @ViewBuilder
    private func fadeMask(leftFade: CGFloat, rightFade: CGFloat) -> some View {
        HStack(spacing: 0) {
            Rectangle().frame(width: 2).opacity(0)

            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0), Color.black]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: leftFade)

            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.black]),
                startPoint: .leading,
                endPoint: .trailing
            )

            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.black.opacity(0)]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: rightFade)

            Rectangle().frame(width: 2).opacity(0)
        }
    }

    // MARK: - Initializer

    private init(
        text: String,
        font: UIFont? = nil,
        leftFade: CGFloat = 8,
        rightFade: CGFloat = 8,
        startDelay: Double = 3.0,
        alignment: Alignment = .center
    ) {
        self.text = text
        self.font = font
        self.leftFade = leftFade
        self.rightFade = rightFade
        self.startDelay = startDelay
        self.alignment = alignment
    }
}

// MARK: - Public Initializers

public extension ScrollingText {
    init(_ text: String, alignment: Alignment = .center) {
        self.init(text: text, font: nil, alignment: alignment)
    }

    init(
        _ text: String,
        leftFade: CGFloat,
        rightFade: CGFloat,
        startDelay: Double,
        alignment: Alignment = .center
    ) {
        self.init(
            text: text,
            font: nil,
            leftFade: leftFade,
            rightFade: rightFade,
            startDelay: startDelay,
            alignment: alignment
        )
    }

    init(
        _ text: String,
        font: UIFont? = nil,
        alignment: Alignment = .center
    ) {
        self.init(
            text: text,
            font: font,
            alignment: alignment
        )
    }

    func font(_ font: UIFont) -> Self {
        var copy = self
        copy.font = font
        return copy
    }
}

extension String {
    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }

    func heightOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.height
    }
}
