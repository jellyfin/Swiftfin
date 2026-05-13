//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

struct DownloadItemView: View {

    @Router
    private var router

    @Injected(\.downloadManager)
    private var downloadManager: DownloadManager

    @State
    private var isPresentingDeleteAlert = false

    let item: DownloadItemDto

    private var sourceItem: BaseItemDto {
        item.item
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                ImageView(item.landscapeImageSources(maxWidth: 800))
                    .failure {
                        SystemImageContentView(systemName: item.systemImage)
                    }
                    .aspectRatio(16 / 9, contentMode: .fill)
                    .clipped()

                VStack(alignment: .leading, spacing: 8) {
                    if sourceItem.type == .episode, let seriesName = sourceItem.seriesName {
                        Text(seriesName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text(item.displayTitle)
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(spacing: 12) {
                        if let label = sourceItem.seasonEpisodeLabel {
                            Text(label)
                        }
                        if let year = sourceItem.premiereDateYear {
                            Text(year)
                        }
                        if let runtime = sourceItem.runTimeLabel {
                            Text(runtime)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if let overview = sourceItem.overview {
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
        .alert(L10n.delete, isPresented: $isPresentingDeleteAlert) {
            Button(L10n.delete, role: .destructive) {
                downloadManager.delete(id: item.task.id)
                router.dismiss()
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            // swiftlint:disable:next hard_coded_display_string
            Text("This will remove the downloaded file from your device.")
        }
    }

    @ViewBuilder
    private var actionRow: some View {
        Button(role: .destructive) {
            isPresentingDeleteAlert = true
        } label: {
            Label(L10n.delete, systemImage: "trash")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
        .tint(.red)
    }
}
