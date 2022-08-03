//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension TruncatedTextView {
    func font(_ font: Font) -> TruncatedTextView {
        var result = self
        result.font = font
        return result
    }

    func lineLimit(_ lineLimit: Int) -> TruncatedTextView {
        var result = self
        result.lineLimit = lineLimit
        return result
    }

    func foregroundColor(_ color: Color) -> TruncatedTextView {
        var result = self
        result.foregroundColor = color
        return result
    }
}

extension String {
    func heightOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let textSize = self.size(withAttributes: fontAttributes)
        return textSize.height
    }

    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let textSize = self.size(withAttributes: fontAttributes)
        return textSize.width
    }
}

struct TruncatedTextView: View {

    @State
    private var truncated: Bool = false
    @State
    private var fullSize: CGFloat = 0

    private var font: Font = .body
    private var lineLimit: Int = 3
    private var foregroundColor: Color = .primary

    let text: String
    let seeMoreAction: () -> Void
    let seeMoreText = "... \(L10n.seeMore)"

    public init(text: String, seeMoreAction: @escaping () -> Void) {
        self.text = text
        self.seeMoreAction = seeMoreAction
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Text(text)
                .font(font)
                .foregroundColor(foregroundColor)
                .lineLimit(lineLimit)
                .if(truncated) { text in
                    text.mask {
                        VStack(spacing: 0) {
                            Color.black

                            HStack(spacing: 0) {
                                Color.black

                                LinearGradient(
                                    stops: [
                                        .init(color: .black, location: 0),
                                        .init(color: .clear, location: 0.1),
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: seeMoreText.widthOfString(usingFont: font.toUIFont()) + 15)
                            }
                            .frame(height: seeMoreText.heightOfString(usingFont: font.toUIFont()))
                        }
                    }
                }

            if truncated {
                #if os(tvOS)
                    Text(seeMoreText)
                        .font(font)
                        .foregroundColor(.purple)
                #else
                    Button {
                        seeMoreAction()
                    } label: {
                        Text(seeMoreText)
                            .font(font)
                            .foregroundColor(.purple)
                    }
                #endif
            }
        }
        .background {
            ZStack {
                if !truncated {
                    if fullSize != 0 {
                        Text(text)
                            .font(font)
                            .lineLimit(lineLimit)
                            .background {
                                GeometryReader { geo in
                                    Color.clear
                                        .onAppear {
                                            if fullSize > geo.size.height {
                                                self.truncated = true
                                            }
                                        }
                                }
                            }
                    }

                    Text(text)
                        .font(font)
                        .lineLimit(10)
                        .fixedSize(horizontal: false, vertical: true)
                        .background {
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        self.fullSize = geo.size.height
                                    }
                            }
                        }
                }
            }
            .hidden()
        }
    }
}
