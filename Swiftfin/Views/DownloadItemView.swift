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

// TODO: POC ONLY! Replace with actual `ItemViews` for Download Types
struct DownloadItemView: View {

    @Router
    private var router

    @Injected(\.downloadManager)
    private var downloadManager: DownloadManager

    @State
    private var task: DownloadTask?

    @State
    private var children: [DownloadTask] = []

    @State
    private var isPresentingDeleteAlert = false

    private let id: String
    private let initialTask: DownloadTask

    init(task: DownloadTask) {
        self.id = task.id
        self.initialTask = task
        let manager = Container.shared.downloadManager()
        self._task = State(initialValue: manager.task(id: task.id) ?? task)
        self._children = State(initialValue: manager.children(of: task.id))
    }

    private var resolvedTask: DownloadTask {
        task ?? initialTask
    }

    private var item: BaseItemDto {
        resolvedTask.item
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                heroSection
                infoSection
                if !children.isEmpty {
                    childrenSection
                }
                actionSection
                    .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
        .navigationTitle(item.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(downloadManager.$tasks) { _ in
            task = downloadManager.task(id: id)
            children = downloadManager.children(of: id)
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

    // MARK: - Sections

    @ViewBuilder
    private var heroSection: some View {
        ImageView(resolvedTask.landscapeImageSources(maxWidth: 800))
            .failure {
                SystemImageContentView(systemName: item.systemImage)
            }
            .aspectRatio(16 / 9, contentMode: .fill)
            .clipped()
    }

    @ViewBuilder
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if item.type == .episode, let seriesName = item.seriesName {
                Text(seriesName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(item.displayTitle)
                .font(.title2)
                .fontWeight(.bold)

            DotHStack {
                if let label = item.seasonEpisodeLabel {
                    Text(label)
                } else if let year = item.premiereDateYear {
                    Text(year)
                }
                if let runtime = item.runTimeLabel {
                    Text(runtime)
                }
                if let rating = item.officialRating {
                    Text(rating)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            statusView

            if let overview = item.overview, !overview.isEmpty {
                Text(overview)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var statusView: some View {
        if let task {
            switch task.state {
            case .queued:
                // swiftlint:disable:next hard_coded_display_string
                stateBadge(text: "Queued", systemImage: "clock", color: .secondary)
            case .downloading:
                if task.isContainer {
                    // swiftlint:disable:next hard_coded_display_string
                    stateBadge(text: "Saving metadata", systemImage: "arrow.down", color: .accentColor)
                } else {
                    progressView(task: task)
                }
            case .paused:
                // swiftlint:disable:next hard_coded_display_string
                stateBadge(text: "Paused", systemImage: "pause.fill", color: .secondary)
            case let .error(reason):
                stateBadge(text: reason.displayTitle, systemImage: "exclamationmark.triangle.fill", color: .red)
            case .completed:
                if downloadManager.isFullyCompleted(task) {
                    // swiftlint:disable:next hard_coded_display_string
                    stateBadge(text: "Downloaded", systemImage: "checkmark.circle.fill", color: .green)
                } else {
                    // swiftlint:disable:next hard_coded_display_string
                    stateBadge(text: "Downloading children", systemImage: "arrow.down", color: .accentColor)
                }
            }
        }
    }

    @ViewBuilder
    private func stateBadge(text: String, systemImage: String, color: Color) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption)
            .foregroundStyle(color)
            .padding(.top, 4)
    }

    @ViewBuilder
    private func progressView(task: DownloadTask) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TimelineView(.periodic(from: .now, by: 0.25)) { _ in
                let live = downloadManager.task(id: id) ?? task
                ProgressView(value: live.progress)
                let bytes = ByteCountFormatter.string(fromByteCount: live.bytesDownloaded, countStyle: .file)
                let total = live.bytesTotal > 0
                    ? ByteCountFormatter.string(fromByteCount: live.bytesTotal, countStyle: .file)
                    : "—"
                // swiftlint:disable:next hard_coded_display_string
                Text("\(bytes) / \(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(childrenTitle)
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(children, id: \.id) { child in
                    childRow(child)
                    if child.id != children.last?.id {
                        Divider()
                            .padding(.leading, 100)
                    }
                }
            }
        }
    }

    private var childrenTitle: String {
        switch children.first?.item.type {
        case .season:
            L10n.seasons
        case .episode:
            L10n.episodes
        default:
            L10n.items
        }
    }

    @ViewBuilder
    private func childRow(_ child: DownloadTask) -> some View {
        Button {
            router.route(to: .downloadItem(task: child))
        } label: {
            HStack(spacing: 12) {
                ImageView(child.landscapeImageSources(maxWidth: 120))
                    .failure {
                        ZStack {
                            Color.secondary.opacity(0.2)
                            Image(systemName: child.item.systemImage)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 80, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                VStack(alignment: .leading, spacing: 2) {
                    Text(child.displayTitle)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if let label = child.item.seasonEpisodeLabel {
                        Text(label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                childStateIndicator(child)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func childStateIndicator(_ child: DownloadTask) -> some View {
        switch child.state {
        case .queued:
            Image(systemName: "clock")
                .foregroundStyle(.secondary)
        case .downloading:
            if child.isContainer {
                Image(systemName: "arrow.down")
                    .foregroundStyle(Color.accentColor)
            } else {
                ProgressView(value: child.progress)
                    .frame(width: 50)
            }
        case .paused:
            Image(systemName: "pause.fill")
                .foregroundStyle(.secondary)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }

    // MARK: - Actions

    @ViewBuilder
    private var actionSection: some View {
        if let task {
            switch task.state {
            case .downloading where !task.isContainer:
                VStack(spacing: 8) {
                    actionButton(L10n.pause, systemImage: "pause.fill", tint: .accentColor) {
                        downloadManager.pause(id: id)
                    }
                    cancelButton
                }
            case .paused:
                VStack(spacing: 8) {
                    actionButton(L10n.resume, systemImage: "play.fill", tint: .accentColor) {
                        downloadManager.resume(id: id)
                    }
                    cancelButton
                }
            case .error:
                VStack(spacing: 8) {
                    actionButton(L10n.retry, systemImage: "arrow.clockwise", tint: .accentColor) {
                        downloadManager.retry(id: id)
                    }
                    cancelButton
                }
            case .queued, .downloading:
                cancelButton
            case .completed:
                actionButton(L10n.delete, systemImage: "trash", tint: .red) {
                    isPresentingDeleteAlert = true
                }
            }
        }
    }

    @ViewBuilder
    private var cancelButton: some View {
        actionButton(L10n.cancel, systemImage: "trash", tint: .red) {
            downloadManager.cancel(id: id)
            router.dismiss()
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
