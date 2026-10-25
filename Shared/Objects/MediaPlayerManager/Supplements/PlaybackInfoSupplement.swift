//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import FactoryKit
import JellyfinAPI
import Observation
import SwiftUI

@MainActor
struct PlaybackInfoSupplement {

    let displayTitle: String = L10n.session
    let itemID: String
    let presentationStyle: VideoPlayerSupplementPresentationStyle = .expanded

    nonisolated var id: String {
        "PlaybackInformation-\(itemID)"
    }
}

extension PlaybackInfoSupplement: VideoPlayerSupplement {

    var body: some View {
        OverlayView(itemID: itemID)
    }

    private struct OverlayView: PlatformView {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets: EdgeInsets

        @Environment(VideoPlayer.ViewState.self)
        private var viewState
        @Environment(MediaSession.self)
        private var mediaSession

        let itemID: String

        @State
        private var viewModel = PlaybackInformationProvider()

        private var mediaSource: MediaSourceInfo? {
            mediaSession.playbackItem?.mediaSource
        }

        private var videoStream: MediaStream? {
            mediaSession.playbackItem?.videoStreams.first
        }

        private var audioStream: MediaStream? {
            guard let playbackItem = mediaSession.playbackItem else { return nil }

            if let selectedIndex = playbackItem.selectedAudioStreamIndex {
                return playbackItem.audioStreams.first { $0.index == selectedIndex }
            }

            return playbackItem.audioStreams.first
        }

        @ViewBuilder
        private var playbackInfoSection: some View {
            Text(L10n.mediaPlayback)
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.vertical, 4)

            LabeledContent(L10n.videoPlayer, value: mediaSession.player?.displayTitle ?? .emptyDash)

            if let playbackItem = mediaSession.playbackItem {
                if let stream = playbackItem.subtitleStreams.first(property: \.index, equalTo: playbackItem.selectedSubtitleStreamIndex) {
                    LabeledContent(L10n.primarySubtitles, value: stream.displayTitle ?? L10n.unknown)
                }

                if let stream = playbackItem.subtitleStreams
                    .first(property: \.index, equalTo: playbackItem.selectedSecondarySubtitleStreamIndex)
                {
                    LabeledContent(L10n.secondarySubtitles, value: stream.displayTitle ?? L10n.unknown)
                }
            }

            if let playMethod = viewModel.currentSession?.playMethodDisplayTitle {
                LabeledContent(L10n.method, value: playMethod)
            }

            if let deliveryProtocol = mediaSource?.protocol {
                LabeledContent(L10n.source, value: deliveryProtocol.rawValue.uppercased())
            }

            if let transcodingSubProtocol = mediaSource?.transcodingSubProtocol {
                LabeledContent(L10n.protocol, value: transcodingSubProtocol.rawValue.uppercased())
            }
        }

        @ViewBuilder
        private var videoInfoSection: some View {
            if videoStream != nil || (mediaSession.player as? any VideoMediaPlayer) != nil {
                Text(L10n.video)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.vertical, 4)

                if let width = videoStream?.width, let height = videoStream?.height {
                    LabeledContent(L10n.videoResolution, value: height.description.multiply(by: width.description))
                }

                if let proxy = mediaSession.player as? any VideoMediaPlayer {
                    LabeledContent(L10n.droppedFrames, value: proxy.videoState.droppedFrames.description)
                    LabeledContent(L10n.corruptedFrames, value: proxy.videoState.corruptedFrames.description)
                }
            }
        }

        @ViewBuilder
        private var streamingInfoSection: some View {
            if let transcodingInfo = viewModel.currentSession?.transcodingInfo {
                Text(viewModel.currentSession?.playMethodDisplayTitle.map { L10n.streamInfoWithMethod($0) } ?? L10n.streamInfo)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.vertical, 4)

                if let videoCodec = transcodingInfo.videoCodec {
                    LabeledContent(
                        L10n.videoCodec,
                        value: transcodingInfo.isVideoDirect == true
                            ? "\(videoCodec.uppercased()) (\(L10n.direct))"
                            : videoCodec.uppercased()
                    )
                }

                if let audioCodec = transcodingInfo.audioCodec {
                    LabeledContent(
                        L10n.audioCodec,
                        value: transcodingInfo.isAudioDirect == true
                            ? "\(audioCodec.uppercased()) (\(L10n.direct))"
                            : audioCodec.uppercased()
                    )
                }

                if let hwAccel = transcodingInfo.hardwareAccelerationType {
                    LabeledContent(L10n.hardwareAcceleration, value: hwAccel.rawValue)
                }

                if let completion = transcodingInfo.completionPercentage {
                    LabeledContent(L10n.transcodeProgress, value: "\(Int(completion))%")
                }
            }
        }

        @ViewBuilder
        private var originalMediaInfoSection: some View {
            if mediaSource != nil || videoStream != nil || audioStream != nil {
                Text(L10n.originalMediaInfo)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.vertical, 4)

                if let container = mediaSource?.container {
                    LabeledContent(L10n.container, value: container)
                }

                if let size = mediaSource?.size {
                    LabeledContent(L10n.size, value: Int64(size).formatted(.byteCount(style: .file)))
                }

                if let bitrate = mediaSource?.bitrate {
                    LabeledContent(L10n.bitrate, value: bitrate.formatted(.bitRate))
                }

                if let codec = videoStream?.codec {
                    let display = videoStream?.profile.map { "\(codec.uppercased()) \($0)" } ?? codec.uppercased()
                    LabeledContent(L10n.videoCodec, value: display)
                }

                if let bitRate = videoStream?.bitRate {
                    LabeledContent(L10n.videoBitRate, value: bitRate.formatted(.bitRate))
                }

                if let videoRangeType = videoStream?.videoRangeType {
                    LabeledContent(L10n.videoRangeType, value: videoRangeType.rawValue)
                }

                if let codec = audioStream?.codec {
                    LabeledContent(L10n.audioCodec, value: codec.uppercased())
                }

                if let bitRate = audioStream?.bitRate {
                    LabeledContent(L10n.audioBitrate, value: bitRate.formatted(.bitRate))
                }

                if let channels = audioStream?.channels {
                    LabeledContent(L10n.channels, value: "\(channels)")
                }

                if let sampleRate = audioStream?.sampleRate {
                    LabeledContent(L10n.audioSampleRate, value: "\(sampleRate) Hz")
                }
            }
        }

        @ViewBuilder
        private var transcodeReasonsSection: some View {
            if let transcodeReasons = viewModel.currentSession?.transcodingInfo?.transcodeReasons, transcodeReasons.isNotEmpty {
                Text(L10n.transcodeReasons)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.vertical, 4)

                ForEach(transcodeReasons, id: \.self) { reason in
                    Text(reason.displayTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }

        var iOSView: some View {
            CompactOrRegularView(
                isCompact: viewState.isCompact
            ) {
                compactView
            } regularView: {
                regularView
            }
            .onFirstAppear { viewModel.observe(itemID: itemID) }
            .labeledContentStyle(.playbackInfo)
            .padding(.leading, safeAreaInsets.leading)
            .padding(.trailing, safeAreaInsets.trailing)
            .padding(.bottom, safeAreaInsets.bottom)
        }

        private var compactView: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    playbackInfoSection
                    videoInfoSection
                    originalMediaInfoSection
                    streamingInfoSection
                    transcodeReasonsSection
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .scrollIndicators(.hidden)
            .edgePadding()
        }

        private var regularView: some View {
            ScrollView {
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        playbackInfoSection
                        videoInfoSection
                        streamingInfoSection
                        transcodeReasonsSection
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                    VStack(alignment: .leading, spacing: 4) {
                        originalMediaInfoSection
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .scrollIndicators(.hidden)
            .edgePadding()
        }

        var tvOSView: some View {
            regularView
                .onFirstAppear { viewModel.observe(itemID: itemID) }
                .labeledContentStyle(.playbackInfo)
                .focusSection()
        }
    }
}

@MainActor
@Observable
final class PlaybackInformationProvider {

    var currentSession: SessionInfoDto?

    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()

    func observe(itemID: String) {
        guard cancellables.isEmpty else { return }

        Container.shared
            .userSessionManager()
            .$currentSession
            .map { session -> AnyPublisher<[SessionInfoDto], Never> in
                session?.serverSocketManager.sessions() ?? Combine.Empty<[SessionInfoDto], Never>().eraseToAnyPublisher()
            }
            .switchToLatest()
            .sink { [weak self] sessions in
                Task { @MainActor in
                    guard let self else { return }

                    let deviceID = Container.shared.currentUserSession()?.client.configuration.deviceID
                    let deviceSessions = sessions.filter { $0.deviceID == deviceID }

                    self.currentSession = deviceSessions.first(where: { $0.nowPlayingItem?.id == itemID }) ?? deviceSessions.first
                }
            }
            .store(in: &cancellables)
    }
}
