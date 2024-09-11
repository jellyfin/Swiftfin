//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

struct ActiveSessionDetailView: View {
    @ObservedObject
    var viewModel: ActiveSessionsViewModel
    @State
    private var imageSources: [ImageSource] = []
    @State
    private var currentDate = Date()

    let iconOrder: [String] = [
        "speaker.wave.2", // Audio related
        "photo.tv", // Video related
        "captions.bubble", // Subtitle related
        "shippingbox", // Container related
        "questionmark.app", // Unknown or other
    ]

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: Get Active Session

    private var session: SessionInfo {
        viewModel.sessions.first ?? SessionInfo()
    }

    // MARK: setImageSources

    private func setImageSources(_ nowPlayingItem: BaseItemDto?) {
        if let imageSource = nowPlayingItem?.cinematicImageSources().first {
            self.imageSources = [imageSource]
        } else {
            self.imageSources = []
        }
    }

    // MARK: Body

    var body: some View {
        List {
            if let nowPlayingItem = session.nowPlayingItem {
                Section(L10n.media) {
                    ImageView(nowPlayingItem.cinematicImageSources().first!)
                        .image { image in
                            image
                        }
                        .placeholder { imageSource in
                            ImageView.DefaultPlaceholderView(blurHash: imageSource.blurHash)
                        }
                        .failure {
                            Color.secondarySystemFill
                                .opacity(0.75)
                        }
                        .id(imageSources.hashValue)
                        .scaledToFill()
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 4
                            )
                        )
                    ActiveSessionsView.ContentSection(session: session)
                    if let overview = nowPlayingItem.overview {
                        Text(overview)
                    }
                }
                Section(L10n.progress) {
                    ActiveSessionsView.ProgressSection(session: session)
                }
            }
            Section("Device") {
                ActiveSessionsView.ClientSection(session: session)
            }
            if session.nowPlayingItem != nil {
                Section(L10n.streams) {
                    streamSection
                }
            } else {
                Section("Last Seen") {
                    ActiveSessionsView.ConnectionSection(session: session, currentDate: currentDate)
                }
            }
            if session.transcodingInfo != nil {
                Section("Reason(s)") {
                    transcodingDetails
                }
            }
        }
        .navigationTitle(session.userName ?? L10n.unknown)
        .onAppear {
            viewModel.send(.refresh)
            setImageSources(session.nowPlayingItem)
        }
        .onChange(of: session.nowPlayingItem) { _ in
            setImageSources(session.nowPlayingItem)
        }
        .onReceive(timer) { _ in
            viewModel.send(.backgroundRefresh)
            currentDate = Date()
        }
    }

    // MARK: Progress Section

    @ViewBuilder
    private var progressSection: some View {
        let playbackPercentage = Double(session.playState?.positionTicks ?? 0) / Double(session.nowPlayingItem?.runTimeTicks ?? 0)

        ActiveSessionsView.TimelineSection(
            playbackPercentage: playbackPercentage,
            transcodingPercentage: (session.transcodingInfo?.completionPercentage ?? 0 / 100.0)
        )
    }

    // MARK: Streaming Details

    @ViewBuilder
    private var streamSection: some View {
        if let nowPlayingItem = session.nowPlayingItem {
            VStack(alignment: .leading, spacing: 8) {

                if let playType = session.playState?.playMethod?.rawValue {
                    HStack {
                        Spacer()
                        Text(playType)
                        Spacer()
                    }
                }

                Divider()

                if let sourceAudioCodec = nowPlayingItem.mediaStreams?.first(where: { $0.type == .audio })?.codec {
                    getMediaComparison(
                        sourceComponent: sourceAudioCodec,
                        destinationComponent: session.transcodingInfo?.audioCodec ?? sourceAudioCodec
                    )
                }

                if let sourceVideoCodec = nowPlayingItem.mediaStreams?.first(where: { $0.type == .video })?.codec {
                    getMediaComparison(
                        sourceComponent: sourceVideoCodec,
                        destinationComponent: session.transcodingInfo?.videoCodec ?? sourceVideoCodec
                    )
                }

                if let sourceContainer = nowPlayingItem.container {
                    getMediaComparison(
                        sourceComponent: sourceContainer,
                        destinationComponent: session.transcodingInfo?.container ?? sourceContainer
                    )
                }
            }
        }
    }

    // MARK: Transcoding Details

    @ViewBuilder
    private var transcodingDetails: some View {
        if let transcodingInfo = session.transcodingInfo,
           let reasons = transcodingInfo.transcodeReasons,
           !reasons.isEmpty
        {
            VStack(alignment: .leading, spacing: 8) {
                let uniqueIcons = Set(reasons.map(\.icon))

                let transcodeIcons = iconOrder.filter { uniqueIcons.contains($0) }

                HStack {
                    Spacer()
                    ForEach(Array(transcodeIcons), id: \.self) { icon in
                        Image(systemName: icon)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }

                Divider()

                VStack(alignment: .center, spacing: 8) {
                    ForEach(reasons, id: \.self) { reason in
                        Text(reason.description)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
            }
        }
    }

    // MARK: Transcoding Details

    private func getMediaComparison(sourceComponent: String, destinationComponent: String?) -> some View {
        HStack {
            Text(sourceComponent.uppercased())
                .frame(maxWidth: .infinity, alignment: .trailing)
            Image(systemName: (destinationComponent != sourceComponent) ? "shuffle" : "arrow.right")
                .frame(maxWidth: .infinity, alignment: .center)
            Text((destinationComponent ?? "").uppercased())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }
}
