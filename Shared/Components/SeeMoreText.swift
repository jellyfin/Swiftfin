//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: fix when using `lineLimit(reserveSpace > 1)`
//       - see more button gets large frame

struct SeeMoreText: View {

    @State
    private var fullTextFrame: CGRect = .zero
    @State
    private var layoutTextFrame: CGRect = .zero

    private var isTruncated: Bool {
        fullTextFrame.height > layoutTextFrame.height
    }

    private let isTruncatedBinding: Binding<Bool>
    private let seeMoreAction: () -> Void
    private let text: Text

    init(
        _ text: String,
        isTruncated: Binding<Bool> = .constant(true),
        seeMoreAction: @escaping () -> Void
    ) {
        self.text = Text(text)
        self.isTruncatedBinding = isTruncated
        self.seeMoreAction = seeMoreAction
    }

    init(
        _ text: Text,
        isTruncated: Binding<Bool> = .constant(true),
        seeMoreAction: @escaping () -> Void
    ) {
        self.text = text
        self.isTruncatedBinding = isTruncated
        self.seeMoreAction = seeMoreAction
    }

    @ViewBuilder
    private var seeMoreText: some View {
        Text(L10n.seeMore)
            .textCase(.uppercase)
            .fontWeight(.semibold)
    }

    @ViewBuilder
    private var textView: some View {
        text
            .trackingFrame($layoutTextFrame)
            .inverseMask(alignment: .bottomTrailing) {
                seeMoreText
                    .padding(.leading, 20)
                    .background {
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        stops: [
                                            .init(color: .clear, location: 0),
                                            .init(color: .black, location: 0.75),
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 20)

                            Rectangle()
                                .fill(Color.black)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .isVisible(isTruncated)
            }
            .overlay(alignment: .bottomTrailing) {
                if isTruncated {
                    seeMoreText
                }
            }
            .background(alignment: .top) {
                text
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .trackingFrame($fullTextFrame)
                    .hidden()
            }
            .backport
            .onChange(of: isTruncated) { _, newValue in
                isTruncatedBinding.wrappedValue = newValue
            }
    }

    var body: some View {
        Button(action: seeMoreAction) {
            textView
        }
        .buttonStyle(.plain)
    }
}
