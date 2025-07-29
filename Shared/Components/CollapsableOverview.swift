//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct CollapsableOverview: View {
    let overviewText: String

    @Default(.accentColor)
    private var accentColor

    @State
    private var isTruncated = false

    private let seeMoreText = "\u{2026}" + L10n.seeMore
    private let seeLessText = "\u{2026}" + L10n.seeLess

    init(text: String) {
        overviewText = text
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Text(overviewText)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(isTruncated ? 3 : nil)
                .background(GeometryReader { geometry in
                    Color.clear.onAppear {
                        determineTruncation(geometry)
                    }
                })
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
                }

            Button {
                isTruncated.toggle()
            } label: {
                Text(isTruncated ? seeMoreText : seeLessText)
                    .foregroundColor(accentColor)
            }
        }
    }

    private func determineTruncation(_ geometry: GeometryProxy) {
        // Calculate the bounding box we'd need to render the
        // text given the width from the GeometryReader.
        let total = overviewText.boundingRect(
            with: CGSize(
                width: geometry.size.width,
                height: .greatestFiniteMagnitude
            ),
            options: .usesLineFragmentOrigin,
            attributes: [.font: UIFont.systemFont(ofSize: 16)],
            context: nil
        )

        let geometryHeightMinusPadding = geometry.size.height - 15
        if total.size.height >= geometryHeightMinusPadding {
            isTruncated = true
        }
    }
}

// #Preview {
//    CollapsableOverview()
// }
