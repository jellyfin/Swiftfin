//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import Logging
import SwiftUI

struct ItemDownloadListView: View {

    // MARK: - Properties

    @Router
    private var router

    let item: BaseItemDto

    init(item: BaseItemDto) {
        self.item = item
        _viewModel = StateObject(wrappedValue: ItemDownloadListViewModel(item: item))
    }

    // MARK: - State

    @StateObject
    private var viewModel: ItemDownloadListViewModel

    @State
    private var showingDeleteAlert = false

    @State
    private var episodeToDelete: DownloadedEpisode?

    // MARK: - Dependencies

    private let logger = Logger.swiftfin()

    // MARK: - Body

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Loading episodes...")
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.downloadedEpisodes.isEmpty {
                emptyView
            } else {
                contentView
            }
        }
        .navigationTitle(item.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Episode", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                episodeToDelete = nil
            }
            Button("Delete", role: .destructive) {
                confirmDeleteEpisode()
            }
        } message: {
            if let episodeToDelete = episodeToDelete {
                Text("Are you sure you want to delete '\(episodeToDelete.displayTitle)'?")
            }
        }
        .onAppear { viewModel.load() }
    }

    // MARK: - Empty State View

    @ViewBuilder
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tv")
                .font(.system(size: 72))
                .foregroundStyle(.secondary)

            Text("No Downloaded Episodes")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Episodes for this series haven't been downloaded yet")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {

        List {

            // Episodes grouped by season
            ForEach(viewModel.sortedSeasons, id: \.self) { seasonNumber in
                Section(header: seasonHeader(for: seasonNumber)) {
                    if let episodes = viewModel.episodesBySeason[seasonNumber] {
                        ForEach(episodes) { episode in
                            DownloadedEpisodeRow(
                                episode: episode,
                                onTap: { handleEpisodeTap(episode) },
                                onDelete: { deleteEpisode(episode) }
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Season Header

    @ViewBuilder
    private func seasonHeader(for seasonNumber: Int) -> some View {
        HStack {
            Text("Season \(seasonNumber)")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            if let episodes = viewModel.episodesBySeason[seasonNumber] {
                Text("\(episodes.count) episodes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Private Methods

    private func handleEpisodeTap(_ episode: DownloadedEpisode) {
        logger.info("User tapped on episode: \(episode.displayTitle)")
        // Navigate to episode player
        router.route(to: .item(item: episode.episodeItem))
    }

    private func deleteEpisode(_ episode: DownloadedEpisode) {
        logger.info("User requested to delete episode: \(episode.displayTitle)")
        episodeToDelete = episode
        showingDeleteAlert = true
    }

    private func confirmDeleteEpisode() {
        guard let episodeToDelete = episodeToDelete else { return }

        logger.info("Confirming deletion of episode: \(episodeToDelete.displayTitle)")

        // Delegate deletion to ViewModel
        viewModel.deleteEpisode(episodeToDelete)

        self.episodeToDelete = nil
    }
}

// MARK: - Downloaded Episode Row

struct DownloadedEpisodeRow: View {

    // MARK: - Properties

    let episode: DownloadedEpisode
    let onTap: () -> Void
    let onDelete: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 6) {
            // Thumbnail
            ImageView(episode.backdropImageURL)
                .failure {
                    Rectangle()
                        .foregroundStyle(.secondary.opacity(0.3))
                        .overlay {
                            Image(systemName: "tv")
                        }
                }
                .aspectRatio(16 / 9, contentMode: .fill)
                .frame(width: 120, height: 67.5)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Episode info
            VStack(alignment: .leading, spacing: 4) {
                // Episode number and title
                HStack {
                    if let episodeNumber = episode.episodeNumber {
                        Text("Episode \(episodeNumber)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }

                    if let runtime = episode.episodeItem.runTimeTicks {
                        let minutes = runtime / 600_000_000
                        Text("\(minutes)m")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    Spacer()

                    // Delete button
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }

                Text(episode.displayTitle)
                    .font(.system(size: 13, weight: .semibold)) // Between subheadline (~15) and caption (~12)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let overview = episode.episodeItem.overview {
                    Text(overview)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
