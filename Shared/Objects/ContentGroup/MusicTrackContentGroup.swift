//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(iOS)

import JellyfinAPI
import SwiftUI

struct MusicTrackContentGroup: ContentGroup {

    let id: String
    let parent: BaseItemDto
    let viewModel: PagingLibraryViewModel<MusicTrackLibrary>

    var _shouldBeResolved: Bool {
        viewModel.elements.isNotEmpty
    }

    init(parent: BaseItemDto) {
        self.id = "\(parent.id ?? "unknown")-music-tracks"
        self.parent = parent
        self.viewModel = .init(
            library: MusicTrackLibrary(parent: parent),
            pageSize: 100
        )
    }

    func body(with viewModel: PagingLibraryViewModel<MusicTrackLibrary>) -> Body {
        Body(parent: parent, viewModel: viewModel)
    }

    struct Body: View {

        let parent: BaseItemDto

        @ObservedObject
        var viewModel: PagingLibraryViewModel<MusicTrackLibrary>

        var body: some View {
            ContentGroupSection {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.elements.enumerated()), id: \.element) { offset, item in
                        TrackRow(
                            item: item,
                            parent: parent,
                            fallbackIndex: offset + 1
                        )
                    }
                }
                .withViewContext(.isListRowSeparatorVisible)
                .background(Color.secondarySystemBackground)
                .clipShape(.rect(cornerRadius: 12, style: .continuous))
                .edgePadding(.horizontal)
            } header: {
                Text(L10n.audio)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .edgePadding(.horizontal)
                    .accessibilityAddTraits(.isHeader)
            }
        }
    }

    private struct TrackRow: View {

        let item: BaseItemDto
        let parent: BaseItemDto
        let fallbackIndex: Int

        private var artists: String? {
            guard let artists = item.artists?.joined(separator: ", "), artists.isNotEmpty else {
                return nil
            }

            return artists
        }

        private var trackIndex: String {
            item.indexNumber.map(String.init) ?? fallbackIndex.formatted()
        }

        private func play() {
            let provider = MediaPlayerItemProvider(item: item) { item in
                try await MediaPlayerItem.build(for: item)
            }
            let queue = MusicMediaPlayerQueue(item: item, parent: parent)

            NavigationRoute.musicPlayer(
                provider: provider,
                queue: queue
            )
        }

        var body: some View {
            ListRow(
                insets: .init(vertical: 12, horizontal: EdgeInsets.edgePadding)
            ) {
                Text(trackIndex)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 24)
            } content: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.displayTitle)
                            .font(.callout)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        if let artists {
                            Text(artists)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 8)

                    if let runtime = item.runtime {
                        Text(runtime, format: .runtime)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            } action: {
                play()
            }
            .accessibilityLabel(item.displayTitle)
            .accessibilityHint(L10n.play)
        }
    }
}

#endif
