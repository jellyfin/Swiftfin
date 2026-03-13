//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct MediaSourceInfoView: PlatformView {

    @FocusState
    private var focusedStream: MediaStream?

    @Router
    private var router

    @State
    private var selectedStream: MediaStream?

    let source: MediaSourceInfo

    @ViewBuilder
    private func streamRow(_ stream: MediaStream) -> some View {
        ChevronButton(stream.displayTitle ?? .emptyDash) {
            router.route(to: .mediaStreamInfo(mediaStream: stream))
        }
        .focused($focusedStream, equals: stream)
        .backport
        .onChange(of: focusedStream) { _, newValue in
            if let newValue {
                selectedStream = newValue
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        Form {
            if let videoStreams = source.videoStreams,
               videoStreams.isNotEmpty
            {
                Section(L10n.video) {
                    ForEach(videoStreams, id: \.self) { stream in
                        streamRow(stream)
                    }
                }
            }

            if let audioStreams = source.audioStreams,
               audioStreams.isNotEmpty
            {
                Section(L10n.audio) {
                    ForEach(audioStreams, id: \.self) { stream in
                        streamRow(stream)
                    }
                }
            }

            if let subtitleStreams = source.subtitleStreams,
               subtitleStreams.isNotEmpty
            {
                Section(L10n.subtitle) {
                    ForEach(subtitleStreams, id: \.self) { stream in
                        streamRow(stream)
                    }
                }
            }
        }
    }

    var iOSView: some View {
        contentView
            .navigationTitle(source.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismiss()
            }
    }

    var tvOSView: some View {
        HStack {
            contentView

            AlternateLayoutView {
                Color.clear
            } content: {
                if let selectedStream {
                    MediaStreamInfoView(mediaStream: selectedStream)
                }
            }
        }
        .backport
        .scrollClipDisabled()
        .navigationTitle(source.displayTitle)
    }
}
