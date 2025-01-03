//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: only allow `view` selection when truncated?
// TODO: fix when also using `lineLimit(reserveSpace > 1)`
// TODO: some false positives for showing see more?
// TODO: allow removing empty lines

struct TruncatedText: View {

    enum SeeMoreType {
        case button
        case view
    }

    @Default(.accentColor)
    private var accentColor

    @State
    private var isTruncated: Bool = false
    @State
    private var fullheight: CGFloat = 0

    private var isTruncatedBinding: Binding<Bool>
    private var onSeeMore: () -> Void
    private let seeMoreText = "\u{2026} See More"
    private var seeMoreType: SeeMoreType
    private let text: String

    @ViewBuilder
    private var textView: some View {
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
                if seeMoreType == .button {
                    Button {
                        onSeeMore()
                    } label: {
                        Text(seeMoreText)
                            .foregroundColor(accentColor)
                    }
                } else {
                    Text(seeMoreText)
                        .foregroundColor(accentColor)
                }
                #endif
            }
        }
        .background {
            ZStack {
                if !isTruncated {
                    if fullheight != 0 {
                        Text(text)
                            .onSizeChanged { newSize in
                                if fullheight > newSize.height {
                                    isTruncated = true
                                }
                            }
                    }

                    Text(text)
                        .lineLimit(10)
                        .fixedSize(horizontal: false, vertical: true)
                        .onSizeChanged { newSize in
                            fullheight = newSize.height
                        }
                }
            }
            .hidden()
        }
        .onChange(of: isTruncated) { newValue in
            isTruncatedBinding.wrappedValue = newValue
        }
    }

    var body: some View {
        if seeMoreType == .button {
            textView
        } else {
            Button {
                onSeeMore()
            } label: {
                textView
            }
            .buttonStyle(.plain)
        }
    }
}

extension TruncatedText {

    init(_ text: String) {
        self.init(
            isTruncatedBinding: .constant(false),
            onSeeMore: {},
            seeMoreType: .button,
            text: text
        )
    }

    func isTruncated(_ isTruncated: Binding<Bool>) -> Self {
        copy(modifying: \.isTruncatedBinding, with: isTruncated)
    }

    func onSeeMore(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSeeMore, with: action)
    }

    func seeMoreType(_ type: SeeMoreType) -> Self {
        copy(modifying: \.seeMoreType, with: type)
    }
}
