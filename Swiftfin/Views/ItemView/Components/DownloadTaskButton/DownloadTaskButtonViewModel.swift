//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

//
//  DownloadTaskButtonViewModel.swift
//

import Combine
import Factory
import JellyfinAPI

@MainActor
final class DownloadTaskButtonViewModel: ObservableObject {

    enum UIState: Equatable {
        case ready
        case downloading(Double) // 0‥1
        case complete
        case error
    }

    // MARK: Inputs

    let item: BaseItemDto
    let mediaSources: [MediaSourceInfo]

    // MARK: Outputs

    @Published
    var uiState: UIState = .ready
    @Published
    var showVersionSheet = false
    @Published
    var showCancelDialog = false
    @Published
    var downloadedMediaSourceIds = Set<String>()

    // MARK: Dependencies

    @Injected(\.downloadManager)
    private var downloadManager

    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    init(
        item: BaseItemDto,
        mediaSources: [MediaSourceInfo]
    ) {
        self.item = item
        self.mediaSources = mediaSources
        updateDownloadedSources()
        bindTask()
    }

    // MARK: Public API

    func handleTap() {
        switch uiState {
        case .ready, .error:
            if mediaSources.count > 1 {
                showVersionSheet = true
            } else if let firstSource = mediaSources.first,
                      let sourceId = firstSource.id,
                      !downloadedMediaSourceIds.contains(sourceId)
            {
                beginDownload(with: firstSource)
            }
        case .complete:
            // Allow opening version sheet even if all are downloaded
            if mediaSources.count > 1 {
                showVersionSheet = true
            }
        // Single version already downloaded - do nothing
        case .downloading:
            showCancelDialog = true
        }
    }

    func beginDownload(with source: MediaSourceInfo?) {
        guard let source = source,
              let sourceId = source.id,
              !downloadedMediaSourceIds.contains(sourceId)
        else {
            return
        }

        var selected = item
        selected.mediaSources = [source]
        downloadManager.download(task: DownloadTask(item: selected))
    }

    func cancelCurrent() {
        if let task = downloadManager.task(for: item) {
            downloadManager.cancel(task: task)
        }
    }

    // MARK: Private

    private func updateDownloadedSources() {
        // Check which media sources are already downloaded
        downloadedMediaSourceIds.removeAll()

        for source in mediaSources {
            guard let sourceId = source.id else { continue }

            // Check if this specific media source is downloaded
            if downloadManager.isMediaSourceDownloaded(item: item, mediaSourceId: sourceId) {
                downloadedMediaSourceIds.insert(sourceId)
            }
        }

        // If single source and it's downloaded, mark as complete
        if mediaSources.count == 1,
           let firstSourceId = mediaSources.first?.id,
           downloadedMediaSourceIds.contains(firstSourceId)
        {
            uiState = .complete
        }
    }

    private func bindTask() {
        // Listen for download state changes
        downloadManager.$downloads
            .compactMap { [weak self] (_: [DownloadTask]) -> DownloadTask? in
                guard let self else { return nil }
                return downloadManager.task(for: item)
            }
            .sink { [weak self] (task: DownloadTask) in
                guard let self else { return }
                switch task.state {
                case .ready, .cancelled: uiState = .ready
                case let .downloading(p): uiState = .downloading(p)
                case .complete:
                    uiState = .complete
                    // Update downloaded sources when download completes
                    updateDownloadedSources()
                case .error: uiState = .error
                }
            }
            .store(in: &cancellables)

        // Also listen for general changes to update downloaded status
        downloadManager.$downloads
            .sink { [weak self] _ in
                guard let self else { return }
                self.updateDownloadedSources()
            }
            .store(in: &cancellables)
    }
}
