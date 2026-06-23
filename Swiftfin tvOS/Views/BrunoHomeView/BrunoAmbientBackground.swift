//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// MARK: - BrunoAmbientBackground

//
// The "streamer gloss" backdrop for the Bruno home: a heavily blurred, dimmed still of the
// current spotlight (ambient film art) under an accent light-glow and an edge vignette, over
// the base page color. Falls back gracefully to just the gradients when no art is available
// (e.g. mock previews or while loading), so the page never reads as flat black. Purely
// decorative — it sits behind the scrolling content and ignores hit-testing.
struct BrunoAmbientBackground: View {

    /// The item whose backdrop tints the page — typically the focused hero spotlight.
    let item: BaseItemDto?

    var body: some View {
        ZStack {
            Color.bruno.page

            if let item {
                ImageView(item.imageSource(.backdrop, maxWidth: 1280))
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .blur(radius: 90)
                    .opacity(0.5)
                    .overlay {
                        // Darken toward the bottom so shelves/text stay legible over the art.
                        LinearGradient(
                            colors: [
                                Color.bruno.page.opacity(0.15),
                                Color.bruno.page.opacity(0.6),
                                Color.bruno.page.opacity(0.92),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .id(item.id)
                    .transition(.opacity)
            }

            // Soft accent light from the top-leading corner.
            RadialGradient(
                colors: [Color.bruno.accent.opacity(0.22), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 1100
            )
            .blendMode(.screen)

            // Edge vignette for depth.
            RadialGradient(
                colors: [.clear, Color.black.opacity(0.5)],
                center: .center,
                startRadius: 520,
                endRadius: 1500
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
