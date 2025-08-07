//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemDownloadSelectionView: View {

    @Router
    private var router

    let item: BaseItemDto

    private let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    private let sizeFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    var body: some View {
        ScrollView(showsIndicators: true) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(item.mediaSources ?? [], id: \.id) { mediaSource in
                    VStack(alignment: .leading, spacing: 4) {
                        // Media source name
                        Text(mediaSource.name ?? "Unknown Source")
                            .font(.headline)

                        // Two-column layout for remaining metadata
                        HStack(alignment: .top, spacing: 20) {
                            // Left column
                            VStack(alignment: .leading, spacing: 4) {

                                // Size
                                if let size = mediaSource.size {
                                    let sizeString = sizeFormatter.string(fromByteCount: Int64(size))
                                    Text("Size: \(sizeString)")
                                        .font(.caption)
                                }

                                // Resolution
                                if let videoStream = mediaSource.videoStreams?.first,
                                   let width = videoStream.width,
                                   let height = videoStream.height
                                {
                                    Text("Resolution: \(width)x\(height)")
                                        .font(.caption)
                                }
                                // Duration
                                if let duration = mediaSource.runTimeTicks {
                                    let seconds = Double(duration) / 10_000_000
                                    if let formatted = durationFormatter.string(from: seconds) {
                                        Text("Length: \(formatted)")
                                            .font(.caption)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // Right column
                            VStack(alignment: .leading, spacing: 4) {

                                // Container
                                if let container = mediaSource.container {
                                    Text("Container: \(container)")
                                        .font(.caption)
                                }

                                // Video codec
                                if let videoCodec = mediaSource.videoStreams?.first?.codec {
                                    Text("Video: \(videoCodec)")
                                        .font(.caption)
                                }
                                // Audio info
                                if let audioStream = mediaSource.audioStreams?.first,
                                   let audioCodec = audioStream.codec
                                {
                                    let audioChannelsString = audioStream.channels != nil ? " (\(audioStream.channels!) ch)" : ""
                                    Text("Audio: \(audioCodec)\(audioChannelsString)")
                                        .font(.caption)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            VStack {
                                DownloadActionButtonWithProgress(
                                    viewModel: .init(),
                                )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    Divider()
                }
            }
            .padding()
        }
        .navigationTitle("Download Selection")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
    }
}
