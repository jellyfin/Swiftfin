//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension SelectUserView {

    struct EmptyUserView: View {

        @AdaptiveLayout
        private var viewLayout

        let action: () -> Void

        private var imageView: some View {
            RelativeSystemImageView(systemName: "plus")
                .foregroundStyle(Color.secondary)
                .aspectRatio(1, contentMode: .fit)
                .backport
                .glassEffect(in: .circle)
        }

        private var addUserButton: some View {
            Button(action: action) {
                if viewLayout.isLarge {
                    imageView
                        .hoverEffect(.highlight)

                    Text(L10n.addUser)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                } else {
                    VStack {
                        imageView

                        Text(L10n.addUser)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .foregroundStyle(.primary, .secondary)
            .buttonBorderShape(.circle)
            #if os(tvOS)
            .buttonStyle(.borderless)
            .coordinatedFocus(Focus.focusedUserButton.rawValue)
            #endif
        }

        var body: some View {
            GeometryReader { geometry in
                #if os(iOS)
                ScrollView {
                    addUserButton
                        .frame(maxWidth: viewLayout.userGridColumns.itemWidth(for: geometry.size.width))
                        .edgePadding(.vertical)
                        .frame(maxWidth: .infinity)
                }
                .defaultScrollAnchor(.center, for: .alignment)
                .scrollBounceBehavior(.basedOnSize)
                #else
                addUserButton
                    .frame(maxWidth: viewLayout.userGridColumns.itemWidth(for: geometry.size.width))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .focusSection()
                #endif
            }
            .edgePadding(.horizontal)
        }
    }
}
