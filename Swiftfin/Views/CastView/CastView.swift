//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import FactoryKit
import JellyfinAPI
import SwiftUI

struct CastView: View {

    @Router
    private var router

    @ObservedObject
    var target: SessionViewModel

    @State
    private var isPresentingReplaceConfirmation = false
    @State
    private var proxy: CastMediaPlayerProxy?

    let provider: MediaPlayerItemProvider

    init(provider: MediaPlayerItemProvider, target: SessionViewModel) {
        self.provider = provider
        self.target = target
    }

    private func cast() {
        if CastMediaPlayerProxy.isPlaying(item: provider.item, in: target.session) {
            proxy = CastMediaPlayerProxy(item: provider.item, session: target)
        } else if let nowPlayingItem = target.session.nowPlayingItem {
            proxy = CastMediaPlayerProxy(item: nowPlayingItem, session: target)
            isPresentingReplaceConfirmation = true
        } else {
            castReplacing()
        }
    }

    private func castReplacing() {
        guard let itemID = provider.item.id else { return }

        target.error = nil
        target.remotePlaybackSession(
            command: .playNow,
            itemIDs: [itemID],
            startPositionTicks: provider.item.userData?.playbackPositionTicks,
            mediaSourceID: provider.mediaSource?.id,
            audioStreamIndex: nil,
            subtitleStreamIndex: nil,
            startIndex: nil
        )

        proxy = CastMediaPlayerProxy(item: provider.item, session: target)
    }

    var body: some View {
        ZStack {
            if let proxy {
                RemoteView(
                    proxy: proxy,
                    target: target
                )
            } else {
                ProgressView()
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(target.session.deviceName ?? L10n.castToDevice)
        .errorMessage($target.error) {
            guard proxy?.hasStarted != true else { return }
            router.dismiss()
        }
        .alert(
            L10n.replace,
            isPresented: $isPresentingReplaceConfirmation
        ) {
            Button(L10n.replace, role: .destructive) {
                castReplacing()
            }

            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(
                L10n.replaceQueueWarning(
                    target.session.nowPlayingItem?.displayTitle ?? L10n.unknown,
                    provider.item.displayTitle
                )
            )
        }
        .onFirstAppear {
            cast()
        }
        .topBarTrailing {
            if target.background.is(.sending) {
                ProgressView()
            }
        }
    }
}

// MARK: - SessionsView

extension CastView {

    struct SessionsView: View {

        @Router
        private var router

        let provider: MediaPlayerItemProvider

        var body: some View {
            ActiveSessionsView(
                userID: Container.shared.currentUserSession()?.user.id,
                castProvider: provider
            )
            .navigationBarCloseButton {
                router.dismiss()
            }
        }
    }
}

// MARK: - RemoteView

extension CastView {

    private struct RemoteView: View {

        @Default(.accentColor)
        private var accentColor

        @Default(.VideoPlayer.jumpBackwardInterval)
        private var jumpBackwardInterval
        @Default(.VideoPlayer.jumpForwardInterval)
        private var jumpForwardInterval

        @Router
        private var router

        @ObservedObject
        var proxy: CastMediaPlayerProxy
        @ObservedObject
        var target: SessionViewModel

        @State
        private var isAdjustingVolume = false
        @State
        private var isPresentingStopConfirmation = false
        @State
        private var isScrubbing = false
        @State
        private var scrubbedSeconds: Double = 0
        @State
        private var volume: Double = 100

        private var displayedItem: BaseItemDto {
            proxy.nowPlayingItem ?? proxy.item
        }

        private var isLiveContent: Bool {
            displayedItem.isLiveStream || displayedItem.channelID != nil
        }

        private var canSeek: Bool {
            !isLiveContent
        }

        private var supportedCommands: [GeneralCommandType] {
            target.session.supportedCommands ?? target.session.capabilities?.supportedCommands ?? []
        }

        private var selectedMediaSourceID: Binding<String> {
            Binding(
                get: { target.session.playState?.mediaSourceID ?? "" },
                set: { newValue in
                    guard let mediaSource = displayedItem.mediaSources?.first(where: { $0.id == newValue }) else { return }
                    proxy.setMediaSource(mediaSource)
                }
            )
        }

        private var selectedAudioStreamIndex: Binding<Int> {
            Binding(
                get: { proxy.selectedAudioStreamIndex },
                set: { newValue in
                    guard let stream = displayedItem.audioStreams.first(where: { $0.index == newValue }) else { return }
                    proxy.setAudioStream(stream)
                }
            )
        }

        private var selectedSubtitleStreamIndex: Binding<Int> {
            Binding(
                get: { proxy.selectedSubtitleStreamIndex },
                set: { newValue in
                    if newValue == -1 {
                        proxy.setSubtitleStream(.none)
                    } else if let stream = displayedItem.subtitleStreams.first(where: { $0.index == newValue }) {
                        proxy.setSubtitleStream(stream)
                    }
                }
            )
        }

        @ViewBuilder
        private var posterSection: some View {
            VStack(spacing: 10) {
                AlternateLayoutView {
                    Color.clear
                } content: { size in
                    PosterImage(
                        item: displayedItem,
                        type: displayedItem.preferredPosterDisplayType,
                        size: .medium,
                        contentMode: .fit
                    )
                    .id(displayedItem.id)
                    .frame(width: size.width, height: size.height)
                    .subtleShadow()
                }

                VStack(alignment: .center, spacing: 5) {
                    if let seriesName = displayedItem.seriesName {
                        Text(seriesName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text(displayedItem.displayTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    ItemView.MetadataHStack(item: displayedItem)
                }

                Divider()

                ItemView.Description(item: displayedItem)
            }
        }

        @ViewBuilder
        private var progressSection: some View {
            VStack(spacing: 5) {
                CapsuleSlider(
                    value: $scrubbedSeconds,
                    total: max(displayedItem.runtime?.seconds ?? 0, 1)
                )
                .onEditingChanged { isEditing in
                    isScrubbing = isEditing

                    if !isEditing {
                        proxy.setSeconds(.seconds(scrubbedSeconds))
                    }
                }
                .gesturePadding(20)
                .frame(height: isScrubbing ? 15 : 10)
                .disabled(!canSeek || !proxy.hasStarted)
                .frame(height: 15)

                HStack {
                    Text(Duration.seconds(scrubbedSeconds), format: .runtime)

                    Spacer()

                    Text(displayedItem.runtime ?? .zero, format: .runtime)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            }
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .onChange(of: proxy.seconds) { _, newValue in
                guard !isScrubbing else { return }
                scrubbedSeconds = newValue.seconds
            }
        }

        private var hasQueue: Bool {
            proxy.queueCount > 1
        }

        @ViewBuilder
        private var controlsSection: some View {
            HStack(spacing: 32) {
                if hasQueue {
                    let isDisabled = proxy.queueIndex == 0

                    Button {
                        target.sendPlaystateCommand(command: .previousTrack, seekPositionTicks: nil)
                    } label: {
                        Image(systemName: "backward.end.fill")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .foregroundStyle(isDisabled ? .secondary : .primary)
                    }
                    .disabled(isDisabled)
                }

                if canSeek {
                    Button {
                        proxy.jumpBackward(jumpBackwardInterval.rawValue)
                    } label: {
                        Image(systemName: jumpBackwardInterval.secondarySystemImage)
                            .font(.title)
                            .frame(width: 44, height: 44)
                    }
                } else if isLiveContent, supportedCommands.contains(.channelDown) {
                    Button {
                        target.sendGeneralCommand(.channelDown)
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.title)
                            .frame(width: 44, height: 44)
                    }
                }

                Button {
                    if proxy.isPaused {
                        proxy.play()
                    } else {
                        proxy.pause()
                    }
                } label: {
                    Image(systemName: proxy.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 48))
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 60, height: 60)
                }

                if canSeek {
                    Button {
                        proxy.jumpForward(jumpForwardInterval.rawValue)
                    } label: {
                        Image(systemName: jumpForwardInterval.systemImage)
                            .font(.title)
                            .frame(width: 44, height: 44)
                    }
                } else if isLiveContent, supportedCommands.contains(.channelUp) {
                    Button {
                        target.sendGeneralCommand(.channelUp)
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.title)
                            .frame(width: 44, height: 44)
                    }
                }

                if hasQueue {
                    let isDisabled = proxy.queueIndex == proxy.queueCount - 1

                    Button {
                        target.sendPlaystateCommand(command: .nextTrack, seekPositionTicks: nil)
                    } label: {
                        Image(systemName: "forward.end.fill")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .foregroundStyle(isDisabled ? .secondary : .primary)
                    }
                    .disabled(isDisabled)
                }
            }
            .foregroundStyle(.primary)
        }

        @ViewBuilder
        private var volumeSection: some View {
            HStack(spacing: 16) {
                if supportedCommands.contains(.toggleMute) {
                    let isMuted = proxy.isMuted

                    Button {
                        proxy.toggleMute()
                    } label: {
                        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .frame(width: 44, height: 44)
                            .backport
                            .glassEffect(
                                .regular.selection(
                                    tint: isMuted ? .secondarySystemBackground : accentColor,
                                    foregroundColor: isMuted ? .primary : accentColor.overlayColor
                                ),
                                in: .circle
                            )
                    }
                    .buttonStyle(BasicHoverButtonStyle())
                }

                if supportedCommands.contains(.setVolume) {
                    Slider(value: $volume, in: 0 ... 100, step: 1) { isEditing in
                        isAdjustingVolume = isEditing

                        if !isEditing {
                            target.sendFullGeneralCommand(
                                GeneralCommand(
                                    arguments: ["Volume": "\(Int(volume))"],
                                    name: .setVolume
                                )
                            )
                        }
                    }
                    .onChange(of: target.session.playState?.volumeLevel) { _, newValue in
                        guard !isAdjustingVolume, let newValue else { return }
                        volume = Double(newValue)
                    }
                }

                if proxy.queueItems.isNotEmpty {
                    queueMenu
                }
            }
        }

        @ViewBuilder
        private var queueMenu: some View {
            Menu {
                ForEach(proxy.queueItems, id: \.id) { queueItem in
                    Button {
                        proxy.playQueueItem(queueItem)
                    } label: {
                        if queueItem.id == displayedItem.id {
                            Label(queueItem.displayTitle, systemImage: "play.fill")
                        } else {
                            Text(queueItem.displayTitle)
                        }
                    }
                }
            } label: {
                Image(systemName: "list.bullet")
                    .frame(width: 44, height: 44)
                    .backport
                    .glassEffect(
                        .regular.selection(
                            tint: .secondarySystemBackground,
                            foregroundColor: .primary
                        ),
                        in: .circle
                    )
            }
            .menuStyle(.button)
            .buttonStyle(.isPressed { isPressed in
                proxy.isSyncSuspended = isPressed
            })
        }

        var body: some View {
            VStack(spacing: 20) {
                posterSection

                if isLiveContent {
                    LiveIndicator()
                } else {
                    progressSection
                }

                controlsSection

                if supportedCommands.contains(.toggleMute) || supportedCommands.contains(.setVolume) || proxy.queueItems
                    .isNotEmpty
                {
                    volumeSection
                }
            }
            .edgePadding()
            .navigationBarMenuButton(onPressed: { isPressed in
                proxy.isSyncSuspended = isPressed
            }) {
                playbackMenuContent
            }
            .topBarTrailing {
                stopButton
            }
            .confirmationDialog(
                L10n.stop,
                isPresented: $isPresentingStopConfirmation,
                titleVisibility: .visible
            ) {
                Button(L10n.stop, role: .destructive) {
                    proxy.stop()
                }

                Button(L10n.cancel, role: .cancel) {}
            } message: {
                Text(L10n.stopPlaybackWarning)
            }
            .onAppear {
                scrubbedSeconds = proxy.seconds.seconds

                if let volumeLevel = target.session.playState?.volumeLevel {
                    volume = Double(volumeLevel)
                }
            }
            .onChange(of: proxy.isEnded) { _, isEnded in
                guard isEnded else { return }
                router.dismiss()
            }
        }

        @ViewBuilder
        private var stopButton: some View {
            Button(L10n.stop, systemImage: "stop.fill", role: .destructive) {
                isPresentingStopConfirmation = true
            }
            .labelStyle(.iconOnly)
            .fontWeight(.semibold)
            .tint(.red)
            .foregroundStyle(.red)
        }

        @ViewBuilder
        private var playbackMenuContent: some View {
            if let mediaSources = displayedItem.mediaSources, mediaSources.count > 1 {
                Menu(L10n.version, systemImage: "list.bullet.rectangle") {
                    Picker(L10n.version, selection: selectedMediaSourceID) {
                        ForEach(mediaSources, id: \.id) { mediaSource in
                            Text(mediaSource.displayTitle)
                                .tag(mediaSource.id ?? "")
                        }
                    }
                }
            }

            if supportedCommands.contains(.setAudioStreamIndex), displayedItem.audioStreams.isNotEmpty {
                Menu(L10n.audio, systemImage: "speaker.wave.2") {
                    Picker(L10n.audio, selection: selectedAudioStreamIndex) {
                        ForEach(displayedItem.audioStreams, id: \.index) { stream in
                            Text(stream.displayTitle ?? L10n.unknown)
                                .tag(stream.index ?? -1)
                        }
                    }
                }
            }

            if supportedCommands.contains(.setSubtitleStreamIndex), displayedItem.subtitleStreams.isNotEmpty {
                Menu(L10n.subtitles, systemImage: "captions.bubble") {
                    Picker(L10n.subtitles, selection: selectedSubtitleStreamIndex) {
                        Text(L10n.none)
                            .tag(-1)

                        ForEach(displayedItem.subtitleStreams, id: \.index) { stream in
                            Text(stream.displayTitle ?? L10n.unknown)
                                .tag(stream.index ?? -1)
                        }
                    }
                }
            }

            if supportedCommands.contains(.setMaxStreamingBitrate) {
                Menu(L10n.maximumBitrate, systemImage: "speedometer") {
                    ForEach(PlaybackBitrate.allCases, id: \.self) { bitrate in
                        Button(bitrate.displayTitle) {
                            target.sendFullGeneralCommand(
                                GeneralCommand(
                                    arguments: ["Bitrate": "\(bitrate.rawValue)"],
                                    name: .setMaxStreamingBitrate
                                )
                            )
                        }
                    }
                }
            }
        }
    }
}
