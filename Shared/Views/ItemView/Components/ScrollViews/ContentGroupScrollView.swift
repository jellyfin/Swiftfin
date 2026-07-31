//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: tvOS black background if not enhanced?

extension ItemView {

    struct ContentGroupScrollView: View {

        @ObservedObject
        var provider: ItemContentGroupProvider

        @FocusState
        private var focusedGroupID: String?

        @State
        private var lastFocusedGroupID: String?

        let groups: [any ContentGroup]
        let isEnhanced: Bool

        private var isHeaderFocused: Bool {
            lastFocusedGroupID == ItemViewFocusID.header
                || lastFocusedGroupID == ItemViewFocusID.play
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

        @ViewBuilder
        private var background: some View {
            AlternateLayoutView {
                Color.clear
            } content: {
                ImageView(backgroundImageItem.landscapeImageSources(
                    environment: .init(maxWidth: 1920)
                ))
                .failure {
                    Color.black
                }
                .aspectRatio(contentMode: .fill)
            }
            .accessibilityHidden(true)
            .overlay {
                Rectangle()
                    .fill(Material.regular)
                    .mask(gradient: .linear) {
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
                #if os(tvOS)
                if isEnhanced {
                    background
                        .ignoresSafeArea()
                }
                #endif

                ScrollView {
                    ContentGroupVStack(
                        groups: groups,
                        focusedGroupID: $focusedGroupID
                    )
                    .environment(\.itemViewFocusedGroupID, $focusedGroupID)
                    .edgePadding(.bottom)
                    .backport
                    .defaultFocus(
                        $focusedGroupID,
                        ItemViewFocusID.play,
                        priority: .userInitiated
                    )
                }
                .trackingFrame(for: .scrollView)
                .ignoresSafeArea(edges: isEnhanced ? .all : .horizontal)
                .scrollIndicators(.hidden)
                .onAppear {
                    // Ensure Play wins if poster rows become focusable in the
                    // same appearance pass as the header.
                    focusedGroupID = ItemViewFocusID.play
                }
            }
            .backport
            .onChange(of: focusedGroupID) {
                guard let focusedGroupID else { return }

                if isEnhanced, focusedGroupID != lastFocusedGroupID {
                    lastFocusedGroupID = focusedGroupID
                }
            }
        }
    }
}
