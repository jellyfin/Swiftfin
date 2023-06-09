//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct TruncatedText: View {

    @Default(.accentColor)
    private var accentColor

    @State
    private var isTruncated: Bool = false
    @State
    private var fullSize: CGFloat = 0

    private let text: String
    private var seeMoreAction: () -> Void
    private let seeMoreText = "... See More"

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Text(text)
                .inverseMask(alignment: .bottomTrailing) {
                    VStack {
                        Spacer()

                        HStack {
                            Spacer()

                            Text("   " + seeMoreText)
                                .background {
                                    LinearGradient(
                                        stops: [
                                            .init(color: .clear, location: 0),
                                            .init(color: .black, location: 0.1),
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                }
                        }
                    }
                    .visible(isTruncated)
                }

            if isTruncated {
                #if os(tvOS)
                Text(seeMoreText)
                    .foregroundColor(accentColor)
                #else
                Button {
                    seeMoreAction()
                } label: {
                    Text(seeMoreText)
                        .foregroundColor(accentColor)
                }
                #endif
            }
        }
        .background {
            ZStack {
                if !isTruncated {
                    if fullSize != 0 {
                        Text(text)
                            .background {
                                GeometryReader { proxy in
                                    Color.clear
                                        .onAppear {
                                            if fullSize > proxy.size.height {
                                                self.isTruncated = true
                                            }
                                        }
                                }
                            }
                    }

                    Text(text)
                        .lineLimit(10)
                        .fixedSize(horizontal: false, vertical: true)
                        .background {
                            GeometryReader { proxy in
                                Color.clear
                                    .onAppear {
                                        self.fullSize = proxy.size.height
                                    }
                            }
                        }
                }
            }
            .hidden()
        }
    }
}

extension TruncatedText {

    init(_ text: String) {
        self.init(
            text: text,
            seeMoreAction: {}
        )
    }

    func seeMoreAction(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.seeMoreAction, with: action)
    }
}
