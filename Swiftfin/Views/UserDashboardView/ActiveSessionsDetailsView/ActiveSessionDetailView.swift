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
    var session: SessionInfo

    // MARK: Body

    var body: some View {
        List {
            if session.nowPlayingItem != nil {
                Section(L10n.media) {
                    if let nowPlayingItem = session.nowPlayingItem {
                        ImageView(nowPlayingItem.cinematicImageSources().first!)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 4
                                )
                            )
                            .scaledToFill()
                    }
                    ActiveSessionsView.ContentSection(session: session)
                    if let overview = session.nowPlayingItem?.overview {
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
                    ActiveSessionsView.ConnectionSection(session: session)
                }
            }
            if session.transcodingInfo != nil {
                Section("Reason(s)") {
                    transcodingDetails
                }
            }
        }
        .navigationTitle((session.userName ?? session.deviceName)!)
    }

    // MARK: Progress Section

    private var progressSection: some View {
        let playbackPercentage = Double(session.playState?.positionTicks ?? 0) / Double(session.nowPlayingItem?.runTimeTicks ?? 0)

        return ActiveSessionsView.TimelineSection(
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

                ForEach(reasons, id: \.self) { reason in
                    HStack {
                        Image(systemName: "arrowtriangle.right.fill")
                            .foregroundColor(.primary)
                            .padding(.trailing, 4)
                        Text(reason.rawValue)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }

    private func getMediaComparison(sourceComponent: String, destinationComponent: String?) -> some View {
        HStack {
            Text(sourceComponent.uppercased())
            Spacer()
            Image(systemName: (destinationComponent != sourceComponent) ? "shuffle" : "arrow.right")
            Spacer()
            Text((destinationComponent ?? "").uppercased())
        }
    }
}
