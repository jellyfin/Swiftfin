//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension RemoteView {

    struct NowPlayingSection: View {

        @StoredValue(.User.itemViewAttributes)
        private var attributes

        @ObservedObject
        private var proxy: CastMediaPlayerProxy

        @State
        private var isScrubbing = false
        @State
        private var scrubbedSeconds: Double = 0

        private let item: BaseItemDto

        init(proxy: CastMediaPlayerProxy, item: BaseItemDto) {
            self.proxy = proxy
            self.item = item
        }

        private var selectedItem: BaseItemDto {
            guard item.isLiveContent, let currentProgram = item.currentProgram else { return item }
            return currentProgram
        }

        private var selectedMediaSource: MediaSourceInfo? {
            let mediaSourceID = proxy.session.session.playState?.mediaSourceID
            return item.mediaSources?.first { $0.id == mediaSourceID } ?? item.mediaSources?.first
        }

        var body: some View {
            VStack(spacing: 20) {
                headerSection
                progressSection
            }
            .onAppear {
                scrubbedSeconds = proxy.seconds.seconds
            }
            .onChange(of: proxy.seconds) { _, newValue in
                guard !isScrubbing else { return }
                scrubbedSeconds = newValue.seconds
            }
            .task(id: item.currentProgram?.endDate) {
                guard item.isLiveContent, let endDate = item.currentProgram?.endDate else { return }

                try? await Task.sleep(for: .seconds(max(endDate.timeIntervalSinceNow + 1, 1)))
                await proxy.refreshNowPlayingItem()
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
                        type: item.preferredPosterDisplayType == .square ? .square : .landscape,
                        size: .medium,
                        contentMode: .fit
                    )
                    .id(item.id)
                    .frame(width: size.width, height: size.height)
                    .subtleShadow()
                }

                VStack(alignment: .center, spacing: 5) {
                    if item.isLiveContent, item.currentProgram != nil {
                        Text(item.displayTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Text(selectedItem.displayTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    ItemView.MetadataHStack(item: selectedItem)
                }

                Divider()

                ItemView.Description(item: selectedItem)

                ItemView.AttributesHStack(
                    attributes: attributes,
                    item: selectedItem,
                    selectedMediaSource: selectedMediaSource,
                    alignment: .leading
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.secondary)
            }
        }

        @ViewBuilder
        private var progressSection: some View {
            VStack(spacing: 5) {
                if item.isLiveContent {
                    LiveIndicator()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                CapsuleSlider(
                    value: $scrubbedSeconds,
                    total: max(item.runtime?.seconds ?? (item.isLiveContent ? scrubbedSeconds : 0), 1)
                )
                .onEditingChanged { isEditing in
                    isScrubbing = isEditing

                    if !isEditing {
                        proxy.setSeconds(.seconds(scrubbedSeconds))
                    }
                }
                .gesturePadding(20)
                .frame(height: isScrubbing ? 15 : 10)
                .foregroundStyle(item.isLiveContent ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                .frame(height: 15)
                .disabled(item.isLiveContent || !proxy.hasStarted)

                HStack {
                    Text(Duration.seconds(scrubbedSeconds), format: .runtime)
                        .contentTransition(.numericText())

                    Spacer()

                    if item.isLiveContent {
                        Text(String.emptyRuntime)
                    } else {
                        Text(item.runtime ?? .zero, format: .runtime)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            }
            .animation(.linear(duration: 0.1), value: isScrubbing)
        }
    }
}
