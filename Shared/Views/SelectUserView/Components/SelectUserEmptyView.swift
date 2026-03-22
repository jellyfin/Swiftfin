//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension SelectUserView {

    struct UserEmptyView: PlatformView {

        private let action: () -> Void

        private var columns: Int {
            UIDevice.isPhone ? 2 : 5
        }

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @ViewBuilder
        private var imageView: some View {
            RelativeSystemImageView(systemName: "plus")
                .foregroundStyle(Color.secondary)
                .background(.thinMaterial)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(.circle)
                .posterShadow()
        }

        @ViewBuilder
        private var addUserButton: some View {
            Button(action: action) {
                #if os(tvOS)
                imageView
                    .hoverEffect(.highlight)

                Text(L10n.addUser)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                #else
                VStack {
                    imageView

                    Text(L10n.addUser)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
                #endif
            }
            .foregroundStyle(.primary, .secondary)
            #if os(tvOS)
                .buttonStyle(.borderless)
                .backport
                .buttonBorderShape(.circle)
            #endif
        }

        var iOSView: some View {
            GeometryReader { geometry in
                addUserButton
                    .frame(maxWidth: (geometry.size.width - EdgeInsets.edgePadding * (CGFloat(columns) + 1)) / CGFloat(columns))
                    .frame(maxWidth: min(geometry.size.width, geometry.size.height), maxHeight: .infinity, alignment: .center)
            }
        }

        var tvOSView: some View {
            addUserButton
                .frame(width: 300)
                .focusSection()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}
