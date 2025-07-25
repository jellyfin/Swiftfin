//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

//
//  MediaSourceSelectionSheet.swift
//

import JellyfinAPI
import SwiftUI

struct MediaSourceSelectionSheet: View {

    @ObservedObject
    var vm: DownloadTaskButtonViewModel
    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        NavigationStack {
            List(vm.mediaSources, id: \.id) { source in
                let isDownloaded = source.id.map { vm.downloadedMediaSourceIds.contains($0) } ?? false

                Button {
                    if !isDownloaded {
                        vm.beginDownload(with: source)
                        dismiss()
                    }
                } label: {
                    HStack {
                        MediaSourceRow(source: source)

                        Spacer()

                        if isDownloaded {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(isDownloaded)
            }
            .navigationTitle("Select Version")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Media Source Row

private struct MediaSourceRow: View {

    let source: MediaSourceInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(source.displayTitle)
                .font(.headline)
                .foregroundStyle(.foreground)

            if let videoStreams = source.videoStreams,
               let firstVideo = videoStreams.first
            {
                HStack {
                    Text("Video:")
                        .font(.caption)
                        .foregroundStyle(.foreground)
                        .fontWeight(.medium)

                    Text("\(firstVideo.width ?? 0) × \(firstVideo.height ?? 0)")
                        .font(.caption)
                        .foregroundStyle(.foreground)

                    if let codec = firstVideo.codec {
                        Text("• \(codec.uppercased())")
                            .font(.caption)
                            .foregroundStyle(.foreground)
                    }

                    Spacer()
                }
            }

            if let audioStreams = source.audioStreams,
               !audioStreams.isEmpty
            {
                HStack {
                    Text("Audio:")
                        .font(.caption)
                        .foregroundStyle(.foreground)
                        .fontWeight(.medium)

                    Text("\(audioStreams.count) track\(audioStreams.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.foreground)

                    if let firstAudio = audioStreams.first,
                       let codec = firstAudio.codec
                    {
                        Text("• \(codec.uppercased())")
                            .font(.caption)
                            .foregroundStyle(.foreground)
                    }

                    Spacer()
                }
            }

            if let subtitleStreams = source.subtitleStreams,
               !subtitleStreams.isEmpty
            {
                HStack {
                    Text("Subtitles:")
                        .font(.caption)
                        .foregroundStyle(.foreground)
                        .fontWeight(.medium)

                    Text("\(subtitleStreams.count) track\(subtitleStreams.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.foreground)

                    Spacer()
                }
            }

            if let size = source.size, size > 0 {
                HStack {
                    Text("Size:")
                        .font(.caption)
                        .foregroundStyle(.foreground)
                        .fontWeight(.medium)

                    Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                        .font(.caption)
                        .foregroundStyle(.foreground)

                    Spacer()
                }
            }

            if let bitrate = source.bitrate, bitrate > 0 {
                HStack {
                    Text("Bitrate:")
                        .font(.caption)
                        .foregroundStyle(.foreground)
                        .fontWeight(.medium)

                    Text("\(bitrate / 1000) kbps")
                        .font(.caption)
                        .foregroundStyle(.foreground)

                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
