//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import Factory
import JellyfinAPI
import SwiftUI

struct DownloadButton: View {

    @ObservedObject
    private var downloadManager = Container.shared.downloadManager()

    let item: BaseItemDto

    private var record: DownloadRecord? {
        guard let id = item.id else { return nil }
        return downloadManager.records.first { $0.id == id }
    }

    var body: some View {
        StateAdapter(initialValue: false) { isPresentingDeleteConfirmation in
            ConditionalMenu(
                isMenu: record == nil || record?.state == .paused || record?.state == .downloading,
                action: {
                    guard let id = item.id else { return }

                    guard let record else {
                        downloadManager.queue(item)
                        return
                    }

                    switch record.state {
                    case .queued:
                        downloadManager.cancel(id: id)
                    case .downloading:
                        downloadManager.pause(id: id)
                    case .paused:
                        downloadManager.resume(id: id)
                    case .error:
                        downloadManager.retry(id: id)
                    case .complete:
                        isPresentingDeleteConfirmation.wrappedValue = true
                    }
                },
                menuContent: {
                    if record == nil {
                        Section(L10n.bitrate) {
                            ForEach(PlaybackBitrate.supportedCases, id: \.self) { bitrate in
                                Button(bitrate.displayTitle, systemImage: "arrow.down") {
                                    downloadManager.queue(item, bitrate: bitrate)
                                }
                            }
                        }
                    } else if let id = item.id, let state = record?.state {
                        switch state {
                        case .downloading:
                            Button(L10n.pause, systemImage: "pause") {
                                downloadManager.pause(id: id)
                            }
                            Button(L10n.cancel, systemImage: "trash", role: .destructive) {
                                downloadManager.cancel(id: id)
                            }
                        case .paused:
                            Button(L10n.resume, systemImage: "play") {
                                downloadManager.resume(id: id)
                            }
                            Button(L10n.cancel, systemImage: "trash", role: .destructive) {
                                downloadManager.cancel(id: id)
                            }
                        default:
                            EmptyView()
                        }
                    }
                },
                label: {
                    Group {
                        if let record {
                            switch record.state {
                            case .downloading, .queued:
                                ProgressView(value: record.progress)
                                    .progressViewStyle(.download)
                            case .paused:
                                Image(systemName: "arrow.down.circle.badge.pause")
                            case .complete:
                                Image(systemName: "arrow.down.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .green)
                            case .error:
                                Image(systemName: "arrow.down.circle.badge.xmark")
                                    .foregroundStyle(.red)
                            }
                        } else {
                            Image(systemName: "arrow.down.circle")
                        }
                    }
                    .id(record?.state)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.25), value: record?.state)
                }
            )
            .confirmationDialog(L10n.delete, isPresented: isPresentingDeleteConfirmation) {
                Button(L10n.delete, role: .destructive) {
                    guard let id = item.id else { return }
                    downloadManager.delete(id: id)
                }
                Button(L10n.cancel, role: .cancel) {}
            } message: {
                // swiftlint:disable:next hard_coded_display_string
                Text("This will remove the downloaded file from your device.")
            }
        }
    }
}
