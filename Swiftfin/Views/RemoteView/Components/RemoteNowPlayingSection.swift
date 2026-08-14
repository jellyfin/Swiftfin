//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct RemoteNowPlayingSection: View {

    @ObservedObject
    var proxy: CastMediaPlayerProxy

    let item: BaseItemDto
    let isLive: Bool

    @State
    private var isScrubbing = false
    @State
    private var scrubbedSeconds: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            headerSection

            if isLive {
                LiveIndicator()
            } else {
                progressSection
            }
        }
        .onAppear {
            scrubbedSeconds = proxy.seconds.seconds
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 10) {
            AlternateLayoutView {
                Color.clear
            } content: { size in
                PosterImage(
                    item: item,
                    type: item.preferredPosterDisplayType,
                    size: .medium,
                    contentMode: .fit
                )
                .id(item.id)
                .frame(width: size.width, height: size.height)
                .subtleShadow()
            }

            VStack(alignment: .center, spacing: 5) {
                if let seriesName = item.seriesName {
                    Text(seriesName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(item.displayTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                ItemView.MetadataHStack(item: item)
            }

            Divider()

            ItemView.Description(item: item)
        }
    }

    @ViewBuilder
    private var progressSection: some View {
        VStack(spacing: 5) {
            CapsuleSlider(
                value: $scrubbedSeconds,
                total: max(item.runtime?.seconds ?? 0, 1)
            )
            .onEditingChanged { isEditing in
                isScrubbing = isEditing

                if !isEditing {
                    proxy.setSeconds(.seconds(scrubbedSeconds))
                }
            }
            .gesturePadding(20)
            .frame(height: isScrubbing ? 15 : 10)
            .disabled(!proxy.hasStarted)
            .frame(height: 15)

            HStack {
                Text(Duration.seconds(scrubbedSeconds), format: .runtime)

                Spacer()

                Text(item.runtime ?? .zero, format: .runtime)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
        .animation(.linear(duration: 0.1), value: isScrubbing)
        .onChange(of: proxy.seconds) { _, newValue in
            guard !isScrubbing else { return }
            scrubbedSeconds = newValue.seconds
        }
    }
}
