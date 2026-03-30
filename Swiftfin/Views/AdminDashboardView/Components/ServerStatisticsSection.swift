//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension AdminDashboardView {

    struct ServerStatisticsSection: View {

        @StateObject
        private var viewModel = ServerStatisticsViewModel()

        var body: some View {
            Group {
                switch viewModel.state {
                case .initial:
                    ProgressView()
                case .content:
                    contentView
                case .error:
                    viewModel.error.map {
                        ErrorView(error: $0)
                    }
                }
            }
            .animation(.linear(duration: 0.2), value: viewModel.state)
            .onFirstAppear {
                viewModel.refresh()
            }
        }

        @ViewBuilder
        private var contentView: some View {
            Section(L10n.statistics) {

                if let systemStorage = viewModel.systemStorage {
                    DisclosureGroup(L10n.folders) {
                        pathRow(title: L10n.cache, folder: systemStorage.cacheFolder)
                        pathRow(title: L10n.imageCache, folder: systemStorage.imageCacheFolder)
                        pathRow(title: L10n.logs, folder: systemStorage.logFolder)
                        pathRow(title: L10n.metadata, folder: systemStorage.internalMetadataFolder)
                        pathRow(title: L10n.programData, folder: systemStorage.programDataFolder)
                        pathRow(title: L10n.transcoding, folder: systemStorage.transcodingTempFolder)
                        pathRow(title: L10n.web, folder: systemStorage.webFolder)
                    }
                }

                if let itemCounts = viewModel.itemCounts {
                    DisclosureGroup(L10n.items) {
                        // Movies
                        itemCount(label: L10n.movies, count: itemCounts.movieCount)

                        // Series
                        itemCount(label: L10n.series, count: itemCounts.seriesCount)
                        itemCount(label: L10n.episodes, count: itemCounts.episodeCount)

                        // Music
                        itemCount(label: L10n.artists, count: itemCounts.artistCount)
                        itemCount(label: L10n.albums, count: itemCounts.albumCount)
                        itemCount(label: L10n.audio, count: itemCounts.songCount)

                        // Books
                        itemCount(label: L10n.books, count: itemCounts.bookCount)

                        // Other
                        itemCount(label: L10n.collections, count: itemCounts.boxSetCount)
                        itemCount(label: L10n.musicVideos, count: itemCounts.musicVideoCount)
                        itemCount(label: L10n.trailers, count: itemCounts.trailerCount)
                    }
                }
            }
        }

        @ViewBuilder
        private func pathRow(title: String, folder: FolderStorageDto?) -> some View {
            if let folder {
                FolderStorageRow(title, folder: folder)
            }
        }

        @ViewBuilder
        private func itemCount(label: String, count: Int?) -> some View {
            if let count, count > 0 {
                LabeledContent(label, value: count.formatted())
            }
        }
    }
}
