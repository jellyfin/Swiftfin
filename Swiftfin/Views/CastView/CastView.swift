//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import OrderedCollections
import SwiftUI

struct CastView: View {

    @StateObject
    private var viewModel = CastViewModel()

    @State
    private var isCastPending = false
    @State
    private var isPresentingReplaceConfirmation = false
    @State
    private var proxy: CastMediaPlayerProxy?

    let provider: MediaPlayerItemProvider?

    private var selectedTarget: SessionViewModel? {
        viewModel.selectedTarget
    }

    private func attach(to target: SessionViewModel?) {
        proxy = target.map { CastMediaPlayerProxy(item: nil, session: $0) }
    }

    // selecting only takes control, casting is always explicit
    private func select(target newTarget: SessionViewModel?) {
        viewModel.select(newTarget)
        attach(to: newTarget)
    }

    private func cast(to target: SessionViewModel) {
        guard let provider else { return }

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
        guard let provider, let target = selectedTarget, let itemID = provider.item.id else { return }

        target.error = nil

        Task {
            await target.remotePlaybackSession(
                command: .playNow,
                itemIDs: [itemID],
                startPositionTicks: provider.item.userData?.playbackPositionTicks,
                mediaSourceID: provider.mediaSource?.id,
                audioStreamIndex: nil,
                subtitleStreamIndex: nil,
                startIndex: nil
            )

            await target.refresh()
        }

        proxy = CastMediaPlayerProxy(item: provider.item, session: target)
    }

    @ViewBuilder
    private var targetPicker: some View {
        Menu {
            Button {
                select(target: nil)
            } label: {
                if selectedTarget == nil {
                    Label(L10n.none, systemImage: "checkmark")
                } else {
                    Text(L10n.none)
                }
            }

            Divider()

            ForEach(viewModel.targets.values.elements, id: \.id) { session in
                Button {
                    select(target: session)
                } label: {
                    if session.id == selectedTarget?.id {
                        Label(session.session.deviceName ?? L10n.unknown, systemImage: "checkmark")
                    } else {
                        Text(session.session.deviceName ?? L10n.unknown)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedTarget?.session.deviceName ?? L10n.selectDevice)
                    .font(.headline)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .backport
            .glassEffect(
                .regular.selection(
                    tint: .secondarySystemBackground,
                    foregroundColor: .primary
                ),
                in: .capsule
            )
        }
        .menuStyle(.button)
        .buttonStyle(.isPressed { isPressed in
            viewModel.isPaused = isPressed
            proxy?.isSyncSuspended = isPressed
        })
    }

    // the item this was opened from can always take over the target
    @ViewBuilder
    private var castButton: some View {
        if let provider, let selectedTarget,
           !CastMediaPlayerProxy.isPlaying(item: provider.item, in: selectedTarget.session)
        {
            Button {
                isCastPending = true
                cast(to: selectedTarget)
            } label: {
                Group {
                    if isCastPending {
                        ProgressView()
                    } else {
                        Label(
                            L10n.castToDevice,
                            systemImage: "tv.badge.wifi"
                        )
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .backport
                .glassEffect(
                    .regular.selection(
                        tint: .blue,
                        foregroundColor: Color.blue.overlayColor
                    ),
                    in: .capsule
                )
            }
            .buttonStyle(BasicHoverButtonStyle())
            .disabled(isCastPending)
            .edgePadding(.horizontal)
        }
    }

    @ViewBuilder
    private var disabledRemote: some View {
        VStack(spacing: 20) {
            if viewModel.state == .initial {
                ProgressView()
            } else if viewModel.targets.isEmpty {
                Text(L10n.noDevicesFound)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            RemoteTouchpad { _ in }

            HStack(spacing: 24) {
                RemoteButton(systemImage: "chevron.backward") {}

                RemoteButton(systemImage: "play.fill", size: 76) {}

                RemoteButton(systemImage: "house.fill") {}
            }
        }
        .foregroundStyle(.secondary)
        .edgePadding([.horizontal, .bottom])
        .disabled(true)
    }

    var body: some View {
        VStack(spacing: 20) {
            if let proxy, let selectedTarget {
                RemoteView(
                    proxy: proxy,
                    target: selectedTarget,
                    viewModel: viewModel
                )
            } else {
                disabledRemote
            }

            castButton
        }
        .edgePadding(.top)
        .animation(.linear(duration: 0.2), value: selectedTarget?.id)
        .backport
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                targetPicker
            }
        }
        .errorMessage($viewModel.error)
        .alert(
            L10n.replace,
            isPresented: $isPresentingReplaceConfirmation
        ) {
            Button(L10n.replace, role: .destructive) {
                castReplacing()
            }

            Button(L10n.cancel, role: .cancel) {
                isCastPending = false
            }
        } message: {
            Text(
                L10n.replaceQueueWarning(
                    selectedTarget?.session.nowPlayingItem?.displayTitle ?? L10n.unknown,
                    provider?.item.displayTitle ?? L10n.unknown
                )
            )
        }
        .onFirstAppear {
            viewModel.refresh()
        }
        .onChange(of: selectedTarget?.id) { _, newValue in
            isCastPending = false

            guard newValue != proxy?.session.id else { return }
            attach(to: selectedTarget)
        }
        .onChange(of: selectedTarget?.session.nowPlayingItem?.id) { _, _ in
            isCastPending = false
        }
        .onChange(of: selectedTarget?.error == nil) { _, hasNoError in
            guard !hasNoError else { return }
            isCastPending = false
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

        @ObservedObject
        var proxy: CastMediaPlayerProxy
        @ObservedObject
        var target: SessionViewModel
        @ObservedObject
        var viewModel: CastViewModel

        @State
        private var isAdjustingVolume = false
        @State
        private var isPresentingStopConfirmation = false
        @State
        private var isPresentingTextEntry = false
        @State
        private var isScrubbing = false
        @State
        private var scrubbedSeconds: Double = 0
        @State
        private var textEntry = ""
        @State
        private var volume: Double = 100

        // the cast item only stands in until the session reports playback
        private var displayedItem: BaseItemDto? {
            proxy.nowPlayingItem ?? (proxy.hasStarted ? nil : proxy.item)
        }

        private var isLiveContent: Bool {
            guard let displayedItem else { return false }
            return displayedItem.isLiveStream || displayedItem.channelID != nil
        }

        private var canSeek: Bool {
            !isLiveContent
        }

        private var hasQueue: Bool {
            proxy.queueCount > 1
        }

        private var supportedCommands: [GeneralCommandType] {
            target.session.supportedCommands ?? target.session.capabilities?.supportedCommands ?? []
        }

        private var hasDirectionalControls: Bool {
            supportedCommands.contains(.moveUp) || supportedCommands.contains(.select)
        }

        private func send(_ command: GeneralCommandType) {
            guard supportedCommands.contains(command) else { return }
            target.sendGeneralCommand(command)
        }

        // the session can end without another socket frame arriving,
        // so confirm it still exists after every control
        private func perform(_ action: () -> Void) {
            setMenuPressed(false)
            action()
            viewModel.background.refresh()
        }

        private func setMenuPressed(_ isPressed: Bool) {
            viewModel.isPaused = isPressed
            proxy.isSyncSuspended = isPressed
        }

        // MARK: Now Playing

        @ViewBuilder
        private func posterSection(item: BaseItemDto) -> some View {
            VStack(spacing: 10) {
                AlternateLayoutView {
                    Color.clear
                } content: { size in
                    PosterImage(
                        item: item,
                        type: item.preferredPosterDisplayType,
                        size: .medium,
                        contentMode: .fit
                    )
                    .id(item.id)
                    .frame(width: size.width, height: size.height)
                    .subtleShadow()
                }

                VStack(alignment: .center, spacing: 5) {
                    if let seriesName = item.seriesName {
                        Text(seriesName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text(item.displayTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    ItemView.MetadataHStack(item: item)
                }

                Divider()

                ItemView.Description(item: item)
            }
        }

        @ViewBuilder
        private func progressSection(item: BaseItemDto) -> some View {
            VStack(spacing: 5) {
                CapsuleSlider(
                    value: $scrubbedSeconds,
                    total: max(item.runtime?.seconds ?? 0, 1)
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

                    Text(item.runtime ?? .zero, format: .runtime)
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

        // MARK: Controls

        @ViewBuilder
        private var playbackControlsSection: some View {
            HStack(spacing: 32) {
                if hasQueue {
                    let isDisabled = proxy.queueIndex == 0

                    Button {
                        perform(proxy.previousItem)
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
                        perform { proxy.jumpBackward(jumpBackwardInterval.rawValue) }
                    } label: {
                        Image(systemName: jumpBackwardInterval.secondarySystemImage)
                            .font(.title)
                            .frame(width: 44, height: 44)
                    }
                } else if supportedCommands.contains(.channelDown) {
                    Button {
                        perform { send(.channelDown) }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.title)
                            .frame(width: 44, height: 44)
                    }
                }

                Button {
                    perform {
                        if proxy.isPaused {
                            proxy.play()
                        } else {
                            proxy.pause()
                        }
                    }
                } label: {
                    Image(systemName: proxy.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 48))
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 60, height: 60)
                }

                if canSeek {
                    Button {
                        perform { proxy.jumpForward(jumpForwardInterval.rawValue) }
                    } label: {
                        Image(systemName: jumpForwardInterval.systemImage)
                            .font(.title)
                            .frame(width: 44, height: 44)
                    }
                } else if supportedCommands.contains(.channelUp) {
                    Button {
                        perform { send(.channelUp) }
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.title)
                            .frame(width: 44, height: 44)
                    }
                }

                if hasQueue {
                    let isDisabled = proxy.queueIndex == proxy.queueCount - 1

                    Button {
                        perform(proxy.nextItem)
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
        private var navigationControlsSection: some View {
            HStack(spacing: 24) {
                RemoteButton(systemImage: "chevron.backward") {
                    perform { send(.back) }
                }
                .disabled(!supportedCommands.contains(.back))

                RemoteButton(
                    systemImage: proxy.isPaused ? "play.fill" : "pause.fill",
                    size: 76
                ) {
                    perform {
                        if proxy.isPaused {
                            proxy.play()
                        } else {
                            proxy.pause()
                        }
                    }
                }

                RemoteButton(systemImage: "house.fill") {
                    perform { send(.goHome) }
                }
                .disabled(!supportedCommands.contains(.goHome))
            }
        }

        @ViewBuilder
        private var inputSection: some View {
            HStack(spacing: 24) {
                if supportedCommands.contains(.goToSearch) {
                    RemoteButton(
                        systemImage: GeneralCommandType.goToSearch.systemImage,
                        size: 44
                    ) {
                        perform { send(.goToSearch) }
                    }
                }

                if supportedCommands.contains(.sendString) {
                    RemoteButton(systemImage: "keyboard", size: 44) {
                        isPresentingTextEntry = true
                    }
                }
            }
        }

        @ViewBuilder
        private var muteButton: some View {
            let isMuted = proxy.isMuted

            Button {
                perform(proxy.toggleMute)
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

        @ViewBuilder
        private var volumeSection: some View {
            HStack(spacing: 16) {
                if supportedCommands.contains(.toggleMute) {
                    muteButton
                }

                if supportedCommands.contains(.setVolume) {
                    CapsuleSlider(value: $volume, total: 100)
                        .onEditingChanged { isEditing in
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
                        .gesturePadding(20)
                        .frame(height: isAdjustingVolume ? 15 : 10)
                        .foregroundStyle(accentColor)
                        .frame(height: 15)
                        .animation(.linear(duration: 0.1), value: isAdjustingVolume)
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
                        perform { proxy.playQueueItem(queueItem) }
                    } label: {
                        if queueItem.id == displayedItem?.id {
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
            .buttonStyle(.isPressed(setMenuPressed))
        }

        @ViewBuilder
        private var stopButton: some View {
            if displayedItem != nil {
                Button(L10n.stop, systemImage: "stop.fill", role: .destructive) {
                    isPresentingStopConfirmation = true
                }
                .labelStyle(.iconOnly)
                .fontWeight(.semibold)
                .tint(.red)
                .foregroundStyle(.red)
            }
        }

        var body: some View {
            VStack(spacing: 20) {
                if let displayedItem {
                    posterSection(item: displayedItem)

                    if isLiveContent {
                        LiveIndicator()
                    } else {
                        progressSection(item: displayedItem)
                    }

                    playbackControlsSection
                } else {
                    if hasDirectionalControls {
                        RemoteTouchpad(send: send)
                    } else {
                        ContentUnavailableView(L10n.nothingPlaying, systemImage: "play.slash")
                            .frame(maxHeight: .infinity)
                    }

                    navigationControlsSection

                    if supportedCommands.contains(.goToSearch) || supportedCommands.contains(.sendString) {
                        inputSection
                    }
                }

                if supportedCommands.contains(.toggleMute) || supportedCommands.contains(.setVolume) || proxy.queueItems
                    .isNotEmpty
                {
                    volumeSection
                }
            }
            .edgePadding([.horizontal, .bottom])
            .navigationBarMenuButton(
                isHidden: displayedItem == nil,
                onPressed: setMenuPressed
            ) {
                playbackMenuContent
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    stopButton
                }
            }
            .confirmationDialog(
                L10n.stop,
                isPresented: $isPresentingStopConfirmation,
                titleVisibility: .visible
            ) {
                Button(L10n.stop, role: .destructive) {
                    proxy.stop()

                    Task {
                        await viewModel.background.refresh()
                    }
                }

                Button(L10n.cancel, role: .cancel) {}
            } message: {
                Text(L10n.stopPlaybackWarning)
            }
            .alert(L10n.sendText, isPresented: $isPresentingTextEntry) {
                TextField(L10n.sendText, text: $textEntry)

                Button(L10n.send) {
                    target.sendFullGeneralCommand(
                        GeneralCommand(
                            arguments: ["String": textEntry],
                            name: .sendString
                        )
                    )

                    textEntry = ""
                }

                Button(L10n.cancel, role: .cancel) {
                    textEntry = ""
                }
            }
            .errorMessage($target.error)
            .onAppear {
                scrubbedSeconds = proxy.seconds.seconds

                if let volumeLevel = target.session.playState?.volumeLevel {
                    volume = Double(volumeLevel)
                }
            }
        }

        @ViewBuilder
        private var playbackMenuContent: some View {
            if let mediaSources = displayedItem?.mediaSources, mediaSources.count > 1 {
                Menu(L10n.version, systemImage: "list.bullet.rectangle") {
                    Picker(L10n.version, selection: selectedMediaSourceID) {
                        ForEach(mediaSources, id: \.id) { mediaSource in
                            Text(mediaSource.displayTitle)
                                .tag(mediaSource.id ?? "")
                        }
                    }
                }
            }

            if supportedCommands.contains(.setAudioStreamIndex), let audioStreams = displayedItem?.audioStreams,
               audioStreams.isNotEmpty
            {
                Menu(L10n.audio, systemImage: "speaker.wave.2") {
                    Picker(L10n.audio, selection: selectedAudioStreamIndex) {
                        ForEach(audioStreams, id: \.index) { stream in
                            Text(stream.displayTitle ?? L10n.unknown)
                                .tag(stream.index ?? -1)
                        }
                    }
                }
            }

            if supportedCommands.contains(.setSubtitleStreamIndex), let subtitleStreams = displayedItem?.subtitleStreams,
               subtitleStreams.isNotEmpty
            {
                Menu(L10n.subtitles, systemImage: "captions.bubble") {
                    Picker(L10n.subtitles, selection: selectedSubtitleStreamIndex) {
                        Text(L10n.none)
                            .tag(-1)

                        ForEach(subtitleStreams, id: \.index) { stream in
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
                            perform {
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

        private var selectedMediaSourceID: Binding<String> {
            Binding(
                get: { target.session.playState?.mediaSourceID ?? "" },
                set: { newValue in
                    guard let mediaSource = displayedItem?.mediaSources?.first(where: { $0.id == newValue }) else { return }
                    perform { proxy.setMediaSource(mediaSource) }
                }
            )
        }

        private var selectedAudioStreamIndex: Binding<Int> {
            Binding(
                get: { proxy.selectedAudioStreamIndex },
                set: { newValue in
                    guard let stream = displayedItem?.audioStreams.first(where: { $0.index == newValue }) else { return }
                    perform { proxy.setAudioStream(stream) }
                }
            )
        }

        private var selectedSubtitleStreamIndex: Binding<Int> {
            Binding(
                get: { proxy.selectedSubtitleStreamIndex },
                set: { newValue in
                    if newValue == -1 {
                        perform { proxy.setSubtitleStream(.init(index: -1)) }
                    } else if let stream = displayedItem?.subtitleStreams.first(where: { $0.index == newValue }) {
                        perform { proxy.setSubtitleStream(stream) }
                    }
                }
            )
        }
    }
}
