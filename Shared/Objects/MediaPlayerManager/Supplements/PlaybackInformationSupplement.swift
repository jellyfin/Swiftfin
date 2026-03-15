//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import SwiftUI

// TODO: have proxies be a `PlaybackInformationProvider`
//       - be labeled pair information

class PlaybackInformationSupplement: ObservableObject, MediaPlayerSupplement {

    let displayTitle: String = L10n.session
    let itemID: String
    let provider: PlaybackInformationProvider

    var id: String {
        "PlaybackInformation-\(itemID)"
    }

    init(itemID: String) {
        self.itemID = itemID
        self.provider = .init(itemID: itemID)
    }

    var videoPlayerBody: some PlatformView {
        OverlayView(viewModel: provider)
    }
}

extension PlaybackInformationSupplement {

    private struct OverlayView: PlatformView {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets: EdgeInsets

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @ObservedObject
        var viewModel: PlaybackInformationProvider

        // MARK: - Data Accessors

        private var mediaSource: MediaSourceInfo? {
            manager.playbackItem?.mediaSource
        }

        private var videoStream: MediaStream? {
            manager.playbackItem?.videoStreams.first
        }

        private var audioStream: MediaStream? {
            guard let playbackItem = manager.playbackItem else { return nil }
            if let selectedIndex = playbackItem.selectedAudioStreamIndex {
                return playbackItem.audioStreams.first { $0.index == selectedIndex }
            }
            return playbackItem.audioStreams.first
        }

        private var session: SessionInfoDto? {
            viewModel.currentSession
        }

        // MARK: - Sections

        @ViewBuilder
        private var playbackInfoSection: some View {
            Text(L10n.mediaPlayback)
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.vertical, 4)

            LabeledContent(L10n.videoPlayer, value: Defaults[.VideoPlayer.videoPlayerType].displayTitle)

            if let playMethod = session?.playMethodDisplayTitle {
                LabeledContent(L10n.method, value: playMethod)
            }

            if let scheme = manager.playbackItem?.url.scheme {
                LabeledContent("Protocol", value: scheme)
            }

            if let transcodingSubProtocol = mediaSource?.transcodingSubProtocol {
                LabeledContent("Stream type", value: transcodingSubProtocol.rawValue.uppercased())
            }
        }

        @ViewBuilder
        private var videoInfoSection: some View {
            if videoStream != nil || (manager.proxy as? any VideoMediaPlayerProxy) != nil {
                Text(L10n.video)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.vertical, 4)

                if let proxy = manager.proxy as? any VideoMediaPlayerProxy {
                    let size = proxy.videoSize.value
                    if size != .zero {
                        LabeledContent("Player dimensions", value: "\(Int(size.width))x\(Int(size.height))")
                    }
                }

                if let width = videoStream?.width, let height = videoStream?.height {
                    LabeledContent("Video resolution", value: "\(width)x\(height)")
                }

                if let proxy = manager.proxy as? any VideoMediaPlayerProxy {
                    LabeledContent("Dropped frames", value: "\(proxy.droppedFrames.value)")
                    LabeledContent("Corrupted frames", value: "\(proxy.corruptedFrames.value)")
                }
            }
        }

        @ViewBuilder
        private var streamingInfoSection: some View {
            if let transcodingInfo = session?.transcodingInfo {
                Text(session?.playMethodDisplayTitle.map { "\($0) Info" } ?? "Stream Info")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.vertical, 4)

                if let videoCodec = transcodingInfo.videoCodec {
                    LabeledContent(
                        "Video codec",
                        value: transcodingInfo.isVideoDirect == true
                            ? "\(videoCodec.uppercased()) (direct)"
                            : videoCodec.uppercased()
                    )
                }

                if let audioCodec = transcodingInfo.audioCodec {
                    LabeledContent(
                        "Audio codec",
                        value: transcodingInfo.isAudioDirect == true
                            ? "\(audioCodec.uppercased()) (direct)"
                            : audioCodec.uppercased()
                    )
                }
            }
        }

        @ViewBuilder
        private var originalMediaInfoSection: some View {
            if mediaSource != nil || videoStream != nil || audioStream != nil {
                Text("Original Media Info")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.vertical, 4)

                if let container = mediaSource?.container {
                    LabeledContent("Container", value: container)
                }

                if let size = mediaSource?.size {
                    LabeledContent("Size", value: Int64(size).formatted(.byteCount(style: .file)))
                }

                if let bitrate = mediaSource?.bitrate {
                    LabeledContent("Bitrate", value: bitrate.formatted(.bitRate))
                }

                if let codec = videoStream?.codec {
                    let display = videoStream?.profile.map { "\(codec.uppercased()) \($0)" } ?? codec.uppercased()
                    LabeledContent("Video codec", value: display)
                }

                if let bitRate = videoStream?.bitRate {
                    LabeledContent(L10n.videoBitRate, value: bitRate.formatted(.bitRate))
                }

                if let videoRangeType = videoStream?.videoRangeType {
                    LabeledContent("Video range type", value: videoRangeType.rawValue)
                }

                if let codec = audioStream?.codec {
                    LabeledContent("Audio codec", value: codec.uppercased())
                }

                if let bitRate = audioStream?.bitRate {
                    LabeledContent("Audio bitrate", value: bitRate.formatted(.bitRate))
                }

                if let channels = audioStream?.channels {
                    LabeledContent(L10n.channels, value: "\(channels)")
                }

                if let sampleRate = audioStream?.sampleRate {
                    LabeledContent("Audio sample rate", value: "\(sampleRate) Hz")
                }
            }
        }

        @ViewBuilder
        private var transcodeReasonsSection: some View {
            if let transcodeReasons = session?.transcodingInfo?.transcodeReasons, transcodeReasons.isNotEmpty {
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

        // MARK: - Platform Views

        var iOSView: some View {
            CompactOrRegularView(
                isCompact: containerState.isCompact
            ) {
                iOSCompactView
            } regularView: {
                iOSRegularView
            }
            .labeledContentStyle(.playbackInfo)
            .padding(.leading, safeAreaInsets.leading)
            .padding(.trailing, safeAreaInsets.trailing)
            .edgePadding(.horizontal)
            .edgePadding(.bottom)
        }

        @ViewBuilder
        private var iOSCompactView: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    playbackInfoSection
                    videoInfoSection
                    originalMediaInfoSection
                    streamingInfoSection
                    transcodeReasonsSection
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .scrollIndicators(.hidden)
        }

        @ViewBuilder
        private var iOSRegularView: some View {
            ScrollView {
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        playbackInfoSection
                        videoInfoSection
                        streamingInfoSection
                        transcodeReasonsSection
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                    VStack(alignment: .leading, spacing: 8) {
                        originalMediaInfoSection
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .scrollIndicators(.hidden)
        }

        var tvOSView: some View {
            iOSRegularView
        }
    }
}

class PlaybackInformationProvider: ViewModel, MediaPlayerObserver {

    @Published
    var currentSession: SessionInfoDto? = nil

    weak var manager: MediaPlayerManager?

    private let itemID: String
    private let timer = PokeIntervalTimer()

    private var currentSessionTask: AnyCancellable?

    init(itemID: String) {
        self.itemID = itemID
        super.init()

        timer.poke(interval: 5)
        timer.sink { [weak self] in
            self?.getCurrentSession()
            self?.timer.poke()
        }
        .store(in: &cancellables)
    }

    private func getCurrentSession() {
        currentSessionTask?.cancel()

        currentSessionTask = Task {
            do {
                let parameters = Paths.GetSessionsParameters(
                    deviceID: userSession.client.configuration.deviceID
                )
                let request = Paths.getSessions(
                    parameters: parameters
                )

                let response = try await userSession.client.send(request)
                let sessions = response.value

                // Match by device, falling back to nowPlayingItem ID
                let matchingSession = sessions.first(where: {
                    $0.nowPlayingItem?.id == itemID
                }) ?? sessions.first

                await MainActor.run {
                    self.currentSession = matchingSession
                }
            } catch is CancellationError {
                // expected when polling resets
            } catch {
                logger.error("Failed to get current session: \(error.localizedDescription)")
            }
        }
        .asAnyCancellable()
    }
}
