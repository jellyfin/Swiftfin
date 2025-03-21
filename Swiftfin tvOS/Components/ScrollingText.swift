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

    // MARK: - Body

    public var body: some View {

        /// Use the provided Font to determine the Text Height and Width
        let currentFont = font ?? UIFont.preferredFont(forTextStyle: .body)
        let stringWidth = widthOfString(text: text, usingFont: currentFont)
        let stringHeight = heightOfString(text: text, usingFont: currentFont)

        let animation = Animation
            .linear(duration: Double(stringWidth) / 30)
            .delay(startDelay)
            .repeatForever(autoreverses: false)

        let nullAnimation = Animation.linear(duration: 0)

        GeometryReader { geo in
            /// Only enable scrolling if the Text exceeds the width of its parent
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
                    /// Enforce leading alignment when scrolling
                    .frame(
                            minWidth: 0,
                            maxWidth: .infinity,
                            minHeight: 0,
                            maxHeight: .infinity,
                            alignment: .leading
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
                        // TODO: 'onChange(of:perform:)' was deprecated in tvOS 17.0
                        .onChange(of: text) {
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
            .onFirstAppear {
                /// Trigger scrolling if needed
                self.animate = needsScrolling
            }
            // TODO: 'onChange(of:perform:)' was deprecated in tvOS 17.0
            .onChange(of: text) { _, newValue in
                let newStringWidth = widthOfString(text: newValue, usingFont: currentFont)
                if newStringWidth > geo.size.width {
                    /// Stop the old animation the Text changes
                    self.animate = false

                    /// Begin the new animation on the next 'run loop'
                    DispatchQueue.main.async {
                        self.animate = true
                    }
                } else {
                    self.animate = false
                }
            }
        }
        /// Enforce the exact size of the text for the Frame
        .frame(height: stringHeight)
        .frame(maxWidth: stringWidth)
        .onDisappear {
            self.animate = false
        }
    }

    // MARK: - Scrolling Pair of Texts

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

    // MARK: - Fade Mask

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

    // MARK: - Get the String's Width

    private func widthOfString(text: String, usingFont font: UIFont) -> CGFloat {
        let semiboldFont = UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(.traitBold)!, size: font.pointSize)

        let fontAttributes = [NSAttributedString.Key.font: semiboldFont]
        let size = text.size(withAttributes: fontAttributes)
        return size.width
    }

    // MARK: - Get the String's Height

    private func heightOfString(text: String, usingFont font: UIFont) -> CGFloat {
        let semiboldFont = UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(.traitBold)!, size: font.pointSize)

        let fontAttributes = [NSAttributedString.Key.font: semiboldFont]
        let size = text.size(withAttributes: fontAttributes)
        return size.height
    }
}

public extension ScrollingText {

    // MARK: - Initialize using Default Values

    init(_ text: String, alignment: Alignment = .center) {
        self.init(text: text, font: nil, alignment: alignment)
    }

    // MARK: - Initialize using Custom Values

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

    // MARK: - Font Modifier

    func font(_ font: UIFont) -> Self {
        var copy = self
        copy.font = font
        return copy
    }
}
