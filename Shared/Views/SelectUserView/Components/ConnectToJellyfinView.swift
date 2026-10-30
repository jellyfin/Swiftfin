//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension SelectUserView {

    struct ConnectToJellyfinView: View {

        @AdaptiveLayout
        private var viewLayout

        @Default(.accentColor)
        private var accentColor

        @Router
        private var router

        var body: some View {
            #if os(iOS)
            ScrollView {
                content
                    .edgePadding(.vertical)
                    .frame(maxWidth: .infinity)
            }
            .defaultScrollAnchor(.center, for: .alignment)
            .scrollBounceBehavior(.basedOnSize)
            .edgePadding(.horizontal)
            #else
            content
            #endif
        }

        private var content: some View {
            VStack {
                Text(L10n.connectToJellyfinServerStart)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    router.route(to: .connectToServer)
                } label: {
                    Text(L10n.connect)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                }
                .fontWeight(.semibold)
                .backport
                .buttonStyle(.glassProminent.shadow(false))
                .tint(accentColor)
                #if os(iOS)
                .controlSize(.large)
                .frame(minHeight: viewLayout.controlHeight)
                #else
                .frame(height: viewLayout.controlHeight)
                #endif
            }
            .frame(maxWidth: viewLayout.value(standard: viewLayout.isAccessibilitySize ? 400 : 250, large: 400))
        }
    }
}
