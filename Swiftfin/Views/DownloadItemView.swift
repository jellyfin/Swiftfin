//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import JellyfinAPI
import SwiftUI

struct DownloadItemView: View {

    @Router
    private var router

    @Injected(\.downloadManager)
    private var downloadManager: DownloadManager

    @State
    private var state: ItemDownloadState

    @State
    private var isPresentingDeleteAlert = false

    private let id: String
    private let initialEntry: DownloadEntry

    init(entry: DownloadEntry) {
        self.id = entry.id
        self.initialEntry = entry
        self._state = State(initialValue: Container.shared.downloadManager().state(for: entry.id))
    }

    private var item: BaseItemDto {
        switch state {
        case .none:
            initialEntry.item
        case let .active(task):
            task.item
        case let .completed(item):
            item.item
        }
    }

    private var heroSources: [ImageSource] {
        switch state {
        case let .completed(item):
            item.landscapeImageSources(maxWidth: 800)
        default:
            []
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                heroView

                VStack(alignment: .leading, spacing: 8) {
                    if item.type == .episode, let seriesName = item.seriesName {
                        Text(seriesName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text(item.displayTitle)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(spacing: 12) {
                        if let label = item.seasonEpisodeLabel {
                            Text(label)
                        }
                        if let year = item.premiereDateYear {
                            Text(year)
                        }
                        if let runtime = item.runTimeLabel {
                            Text(runtime)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if case let .active(task) = state {
                        progressSection(task: task)
                    }

                    if let overview = item.overview {
                        Text(overview)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal)

                actionRow
                    .padding(.horizontal)
            }
        }
        .navigationTitle(item.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(downloadManager.statePublisher(for: id)) { newState in
            state = newState
        }
        .alert(L10n.delete, isPresented: $isPresentingDeleteAlert) {
            Button(L10n.delete, role: .destructive) {
                downloadManager.delete(id: id)
                router.dismiss()
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            // swiftlint:disable:next hard_coded_display_string
            Text("This will remove the downloaded file from your device.")
        }
    }

    @ViewBuilder
    private var heroView: some View {
        ImageView(heroSources)
            .failure {
                SystemImageContentView(systemName: item.systemImage)
            }
            .aspectRatio(16 / 9, contentMode: .fill)
            .clipped()
    }

    @ViewBuilder
    private func progressSection(task: DownloadTask) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TimelineView(.periodic(from: .now, by: 0.25)) { _ in
                let live = downloadManager.task(id: id) ?? task
                ProgressView(value: live.progress)
                let bytes = ByteCountFormatter.string(fromByteCount: live.bytesDownloaded, countStyle: .file)
                let total = live.bytesTotal > 0
                    ? ByteCountFormatter.string(fromByteCount: live.bytesTotal, countStyle: .file)
                    : "—"
                Text("\(bytes) / \(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if case let .error(reason) = task.state {
                Text(reason.displayTitle)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var actionRow: some View {
        switch state {
        case let .active(task):
            VStack(spacing: 8) {
                switch task.state {
                case .downloading:
                    actionButton(L10n.pause, systemImage: "pause.fill", tint: .accentColor) {
                        downloadManager.pause(id: id)
                    }
                case .paused:
                    actionButton(L10n.resume, systemImage: "play.fill", tint: .accentColor) {
                        downloadManager.resume(id: id)
                    }
                case .error:
                    actionButton(L10n.retry, systemImage: "arrow.clockwise", tint: .accentColor) {
                        downloadManager.retry(id: id)
                    }
                case .queued:
                    EmptyView()
                }

                actionButton(L10n.cancel, systemImage: "trash", tint: .red) {
                    downloadManager.cancel(id: id)
                    router.dismiss()
                }
            }
        case .completed:
            actionButton(L10n.delete, systemImage: "trash", tint: .red) {
                isPresentingDeleteAlert = true
            }
        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    private func actionButton(_ title: String, systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(role: tint == .red ? .destructive : .none) {
            action()
        } label: {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
        .tint(tint)
    }
}
