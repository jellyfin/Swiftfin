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

// Data models moved into DownloadListViewModel

struct DownloadListView: View {

    // MARK: - Properties

    var error: Error?

    // MARK: - State Properties

    @Router
    private var router

    @StateObject
    private var viewModel = DownloadListViewModel()

    // ViewModel holds data; view manages UI-only state

    @State
    private var showingDeleteAlert = false

    @State
    private var showingDeleteAllAlert = false

    @State
    private var showingVersionSelectionAlert = false

    @State
    private var showToDelete: DownloadedShow?

    @State
    private var movieToDelete: DownloadedMovie?

    @State
    private var selectedMovie: DownloadedMovie?

    // MARK: - Dependencies

    private let logger = Logger.swiftfin()

    // MARK: - Computed Properties

    private var totalStorageUsed: String { viewModel.totalStorageUsedText }

    private var totalItemCount: Int { viewModel.totalItemCount }

    // MARK: - Empty State View

    @ViewBuilder
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 72))
                .foregroundStyle(.secondary)

            Text("No Downloads")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Download content to watch offline")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        ScrollView {

            VStack(alignment: .leading, spacing: 20) {
                // Storage summary header
                HStack(alignment: .center, spacing: 10) {

                    Spacer()
                    if let error {
                        Text(error.localizedDescription)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.orange.opacity(0.2))
                            .foregroundStyle(.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    if !viewModel.downloadedShows.isEmpty || !viewModel.downloadedMovies.isEmpty {
                        Text("\(totalItemCount) items • \(totalStorageUsed)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.secondary.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal)

                // Downloads list
                LazyVStack(spacing: 12) {
                    // Downloaded Shows
                    ForEach(viewModel.downloadedShows) { show in
                        DownloadedShowRow(
                            show: show,
                            onTap: { handleShowTap(show) },
                            onDelete: { deleteDownloadedShow(show) }
                        )
                    }

                    // Downloaded Movies
                    ForEach(viewModel.downloadedMovies) { movie in
                        DownloadedMovieRow(
                            movie: movie,
                            onTap: { handleMovieTap(movie) },
                            onDelete: { deleteDownloadedMovie(movie) }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .refreshable { await viewModel.refresh() }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                        Text("Loading downloads...")
                            .foregroundStyle(.secondary)
                    }
                } else if viewModel.downloadedShows.isEmpty && viewModel.downloadedMovies.isEmpty {
                    emptyView
                } else {
                    contentView
                }
            }
            .navigationTitle(L10n.downloads)
            .navigationBarTitleDisplayMode(.large)
            .alert("Delete Download", isPresented: $showingDeleteAlert) {
                Button(L10n.cancel, role: .cancel) {
                    showToDelete = nil
                    movieToDelete = nil
                }
                Button(L10n.delete, role: .destructive) {
                    confirmDelete()
                }
            } message: {
                if let showToDelete = showToDelete {
                    Text("Are you sure you want to delete '\(showToDelete.displayTitle)' and all its episodes?")
                } else if let movieToDelete = movieToDelete {
                    Text("Are you sure you want to delete '\(movieToDelete.displayTitle)'?")
                } else {
                    Text("Are you sure you want to delete this downloaded item?")
                }
            }
            .alert("Delete All Downloads", isPresented: $showingDeleteAllAlert) {
                Button(L10n.cancel, role: .cancel) {}
                Button("Delete All", role: .destructive) {
                    confirmDeleteAll()
                }
            } message: {
                Text("Are you sure you want to delete all \(totalItemCount) downloaded items? This action cannot be undone.")
            }
            .alert("Select Version", isPresented: $showingVersionSelectionAlert) {
                if let selectedMovie = selectedMovie {
                    ForEach(selectedMovie.versions, id: \.id) { version in
                        Button(version.displayName) {
                            playMovieVersion(version)
                        }
                    }
                    Button(L10n.cancel, role: .cancel) {
                        self.selectedMovie = nil
                    }
                }
            } message: {
                if let selectedMovie = selectedMovie {
                    Text("Select which version of '\(selectedMovie.displayTitle)' to play:")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.downloadedShows.isEmpty || !viewModel.downloadedMovies.isEmpty {
                        Button {
                            logger.info("User requested to delete all downloads")
                            showingDeleteAllAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.load()
        }
    }

    // MARK: - Private Methods

    // Data logic moved into ViewModel

    private func deleteDownloadedShow(_ show: DownloadedShow) {
        logger.info("User requested to delete show: \(show.displayTitle)")
        showToDelete = show
        showingDeleteAlert = true
    }

    private func deleteDownloadedMovie(_ movie: DownloadedMovie) {
        logger.info("User requested to delete movie: \(movie.displayTitle)")
        movieToDelete = movie
        showingDeleteAlert = true
    }

    private func confirmDelete() {
        if let showToDelete = showToDelete {
            logger.info("Confirming deletion of show: \(showToDelete.displayTitle)")

            viewModel.deleteShow(id: showToDelete.id)

            self.showToDelete = nil

        } else if let movieToDelete = movieToDelete {
            logger.info("Confirming deletion of movie: \(movieToDelete.displayTitle)")

            viewModel.deleteMovie(id: movieToDelete.id)

            self.movieToDelete = nil
        }
    }

    private func confirmDeleteAll() {
        logger.info("Confirming deletion of all downloads")
        viewModel.deleteAll()
    }

    private func handleShowTap(_ show: DownloadedShow) {
        logger.info("User tapped on show: \(show.displayTitle)")
        router.route(to: .itemDownloadList(item: show.seriesItem))
    }

    private func handleMovieTap(_ movie: DownloadedMovie) {
        if movie.hasMultipleVersions {
            selectedMovie = movie
            showingVersionSelectionAlert = true
        } else {
            // Single version - play directly
            if let version = movie.versions.first {
                playMovieVersion(version)
            }
        }
    }

    private func playMovieVersion(_ downloadedVersion: DownloadedVersion) {
        logger.warning("Player will be implemented later")
    }
}

// MARK: - Downloaded Show Row

struct DownloadedShowRow: View {

    // MARK: - Properties

    let show: DownloadedShow
    let onTap: () -> Void
    let onDelete: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Thumbnail
                ImageView(show.primaryImageURL ?? show.backdropImageURL)
                    .pipeline(.Swiftfin.local)
                    .failure {
                        Rectangle()
                            .foregroundStyle(.secondary.opacity(0.3))
                            .overlay {
                                Image(systemName: "tv")
                            }
                    }
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Content info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text(show.displayTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(2)

                        Spacer()

                        Button {
                            onDelete()
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }

                    if let overview = show.seriesItem.overview {
                        Text(overview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }

                    // Metadata badges
                    HStack {
                        if let year = show.seriesItem.productionYear {
                            Text(String(year))
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.secondary.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        Text("\(show.episodeCount) episodes")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        if show.seasons.count > 1 {
                            Text("\(show.seasons.count) seasons")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.secondary.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        Spacer()
                    }
                }
            }
            .padding()
            .background(.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Downloaded Movie Row

struct DownloadedMovieRow: View {

    // MARK: - Properties

    let movie: DownloadedMovie
    let onTap: () -> Void
    let onDelete: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Thumbnail
                ImageView(movie.primaryImageURL ?? movie.backdropImageURL)
                    .pipeline(.Swiftfin.local)
                    .failure {
                        Rectangle()
                            .foregroundStyle(.secondary.opacity(0.3))
                            .overlay {
                                Image(systemName: "film")
                            }
                    }
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Content info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text(movie.displayTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(2)

                        Spacer()

                        Button {
                            onDelete()
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }

                    if let overview = movie.movieItem.overview {
                        Text(overview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }

                    // Metadata badges
                    HStack {
                        if let year = movie.movieItem.productionYear {
                            Text(String(year))
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.secondary.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        if let runtime = movie.movieItem.runTimeTicks {
                            let minutes = runtime / 600_000_000 // Convert ticks to minutes
                            Text("\(minutes)m")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                        }

                        if movie.hasMultipleVersions {
                            Text("\(movie.versions.count) versions")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        Spacer()
                    }
                }
            }
            .padding()
            .background(.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
