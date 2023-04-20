//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct TruncatedTextView: View {

    @Default(.accentColor)
    private var accentColor

    @State
    private var truncated: Bool = false
    @State
    private var fullSize: CGFloat = 0

    private var font: Font
    private var lineLimit: Int
    private let text: String
    private var seeMoreAction: () -> Void
    private let seeMoreText = "... \(L10n.seeMore)"

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Text(text)
                .font(font)
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
                                .frame(width: seeMoreText.widthOfString(usingFont: font.uiFont) + 15)
                            }
                            .frame(height: seeMoreText.heightOfString(usingFont: font.uiFont))
                        }
                    }
                }

            if truncated {
                #if os(tvOS)
                Text(seeMoreText)
                    .font(font)
                    .foregroundColor(accentColor)
                #else
                Button {
                    seeMoreAction()
                } label: {
                    Text(seeMoreText)
                        .font(font)
                        .foregroundColor(accentColor)
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

extension TruncatedTextView {

    init(text: String) {
        self.init(
            font: .body,
            lineLimit: 1000,
            text: text,
            seeMoreAction: {}
        )
    }

    func font(_ font: Font) -> Self {
        copy(modifying: \.font, with: font)
    }

    func lineLimit(_ limit: Int) -> Self {
        copy(modifying: \.lineLimit, with: limit)
    }

    func seeMoreAction(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.seeMoreAction, with: action)
    }
}
