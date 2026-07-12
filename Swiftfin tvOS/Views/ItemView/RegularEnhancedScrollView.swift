//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct RegularEnhancedScrollView: View {

        @ObservedObject
        var provider: ItemContentGroupProvider

        @FocusState
        private var focusedGroupID: String?

        let groups: [any ContentGroup]

        private var isHeaderFocused: Bool {
            focusedGroupID == "itemView-header"
        }

        private var backgroundImageItem: BaseItemDto {
            if provider.item.type == .person || provider.item.type == .musicArtist,
               let randomItem = provider.randomBackdropItem
            {
                randomItem
            } else {
                provider.item
            }
        }

        private var backgroundImageSources: [ImageSource] {
            backgroundImageItem.landscapeImageSources(
                environment: .init(
                    maxWidth: 1920,
                    useParent: false
                )
            )
        }

        @ViewBuilder
        private var background: some View {
            AlternateLayoutView {
                Color.clear
            } content: {
                ImageView(backgroundImageSources)
                    .failure {
                        Color.black
                    }
                    .aspectRatio(contentMode: .fill)
            }
            .accessibilityHidden(true)
            .overlay {
                Rectangle()
                    .fill(Material.regular)
                    .maskLinearGradient {
                        if isHeaderFocused {
                            (location: 0.3, opacity: 0)
                        } else {
                            (location: 0, opacity: 1)
                        }

                        (location: 1, opacity: 1)
                    }
            }
            .animation(.linear(duration: 0.2), value: isHeaderFocused)
        }

        var body: some View {
            ZStack {
                background
                    .ignoresSafeArea()

                ScrollView {
                    ContentGroupVStack(
                        groups: groups,
                        focusedGroupID: $focusedGroupID
                    )
                    .edgePadding(.bottom)
                }
                .trackingFrame(for: .scrollView)
                .ignoresSafeArea()
                .scrollIndicators(.hidden)
            }
        }
    }
}
