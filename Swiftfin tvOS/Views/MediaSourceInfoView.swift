//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct MediaSourceInfoView: View {

    @FocusState
    private var selectedMediaStream: MediaStream?

    @State
    private var lastSelectedMediaStream: MediaStream?

    let source: MediaSourceInfo

    @ViewBuilder
    private var content: some View {
        GeometryReader { proxy in
            VStack(alignment: .center) {

                Text(source.displayTitle)
                    .font(.title)
                    .frame(maxHeight: proxy.size.height * 0.33)

                HStack {
                    Form {
                        if let videoStreams = source.videoStreams,
                           videoStreams.isNotEmpty
                        {
                            Section(L10n.video) {
                                ForEach(videoStreams, id: \.self) { stream in
                                    Button {
                                        Text(stream.displayTitle ?? .emptyDash)
                                    }
                                    .focused($selectedMediaStream, equals: stream)
                                }
                            }
                        }

                        if let audioStreams = source.audioStreams,
                           audioStreams.isNotEmpty
                        {
                            Section(L10n.audio) {
                                ForEach(audioStreams, id: \.self) { stream in
                                    Button {
                                        Text(stream.displayTitle ?? .emptyDash)
                                    }
                                    .focused($selectedMediaStream, equals: stream)
                                }
                            }
                        }

                        if let subtitleStreams = source.subtitleStreams,
                           subtitleStreams.isNotEmpty
                        {
                            Section(L10n.subtitle) {
                                ForEach(subtitleStreams, id: \.self) { stream in
                                    Button {
                                        Text(stream.displayTitle ?? .emptyDash)
                                    }
                                    .focused($selectedMediaStream, equals: stream)
                                }
                            }
                        }
                    }

                    Form {
                        if let lastSelectedMediaStream {
                            Section {
                                ForEach(lastSelectedMediaStream.metadataProperties, id: \.label) { property in
                                    Button {
                                        LabeledContent(
                                            property.label,
                                            value: property.value
                                        )
                                    }
                                }
                            }

                            if lastSelectedMediaStream.colorProperties.isNotEmpty {
                                Section(L10n.color) {
                                    ForEach(lastSelectedMediaStream.colorProperties, id: \.label) { property in
                                        Button {
                                            LabeledContent(
                                                property.label,
                                                value: property.value
                                            )
                                        }
                                    }
                                }
                            }

                            if lastSelectedMediaStream.deliveryProperties.isNotEmpty {
                                Section(L10n.delivery) {
                                    ForEach(lastSelectedMediaStream.deliveryProperties, id: \.label) { property in
                                        Button {
                                            LabeledContent(
                                                property.label,
                                                value: property.value
                                            )
                                        }
                                    }
                                }
                            }
                        } else {
                            Button {
                                Text(L10n.none)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
        }
        .onChange(of: selectedMediaStream) { _, newValue in
            guard let newValue else { return }
            lastSelectedMediaStream = newValue
        }
    }

    var body: some View {
        ZStack {
            BlurView()

            content
        }
        .ignoresSafeArea()
    }
}
