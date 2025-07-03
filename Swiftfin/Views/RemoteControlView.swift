//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct RemoteControlView: View {

    @StateObject
    private var viewModel: SessionManagerViewModel

    @ObservedObject
    private var box: BindingBox<SessionInfoDto?>

    @State
    private var volumeLevel: Double = 50

    @State
    private var isKeyboardPresented = false

    @State
    private var keyboardInput = ""

    private var session: SessionInfoDto {
        box.value!
    }

    init(box: BindingBox<SessionInfoDto?>) {
        self.box = box
        _viewModel = StateObject(wrappedValue: SessionManagerViewModel(box.value!))
        _volumeLevel = State(initialValue: Double(box.value?.playState?.volumeLevel ?? 50))
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Media Info Section

            mediaInfoSection

            Spacer()

            // MARK: Progress Section

            if session.nowPlayingItem != nil {
                // progressSection
            }

            // MARK: Playback Controls

            if session.nowPlayingItem != nil {
                playbackControlsSection
                    .padding(.horizontal, 20)
            }

            // MARK: Volume and Additional Controls

            bottomControlsSection

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $isKeyboardPresented, onDismiss: sendKeyboardInput) {
            keyboardSheet
        }
        .navigationTitle(session.nowPlayingItem?.displayTitle ?? session.deviceName ?? L10n.unknown)
    }

    // MARK: Media Info Section

    private var mediaInfoSection: some View {
        VStack(spacing: 16) {

            if let nowPlayingItem = session.nowPlayingItem {
                AnyView(
                    Group {
                        if nowPlayingItem.type == .audio {
                            ZStack {
                                Color.clear

                                ImageView(nowPlayingItem.squareImageSources(maxWidth: 500))
                                    .failure {
                                        SystemImageContentView(systemName: nowPlayingItem.systemImage)
                                    }
                            }
                            .squarePosterStyle()
                        } else {
                            ZStack {
                                Color.clear

                                ImageView(nowPlayingItem.portraitImageSources(maxWidth: 500))
                                    .failure {
                                        SystemImageContentView(systemName: nowPlayingItem.systemImage)
                                    }
                            }
                            .posterStyle(.portrait)
                        }
                    }
                )
                .frame(alignment: .center)
                .padding(.vertical)
            } else {
                // MARK: D-Pad Controls

                VStack {

                    VStack(spacing: 20) {

                        // MARK: Up Button

                        dPadButton(systemName: "chevron.up", command: .moveUp)

                        // MARK: Middle Row

                        HStack(spacing: 20) {

                            // MARK: Left Button

                            dPadButton(systemName: "chevron.left", command: .moveLeft)

                            // MARK: Select Button

                            Button {
                                viewModel.send(.command(.select))
                            } label: {
                                Image(systemName: "circle")
                                    .font(.title)
                                    .foregroundColor(.black)
                                    .frame(width: 60, height: 60)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }

                            // MARK: Right Button

                            dPadButton(systemName: "chevron.right", command: .moveRight)
                        }

                        // MARK: Down Button

                        dPadButton(systemName: "chevron.down", command: .moveDown)
                    }
                    .frame(maxHeight: 300)

                    Spacer()

                    HStack {
                        Spacer()

                        // MARK: Back Button

                        dPadButton(systemName: "arrow.backward", command: .back)

                        Spacer()

                        // MARK: Home Button

                        dPadButton(systemName: "house.fill", command: .goHome)

                        Spacer()
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .padding(.top, 20)
    }

    // MARK: Playback Controls Section

    private var playbackControlsSection: some View {
        HStack(spacing: 40) {

            // MARK: Rewind 10s

            controlButton(
                systemName: "gobackward.10",
                action: { seekRelative(-100_000_000) },
                enabled: canSeek
            )

            // MARK: Previous Track

            controlButton(
                systemName: "backward.end.alt.fill",
                action: { viewModel.send(.playState(.previousTrack)) },
                enabled: canControlMedia
            )

            // MARK: Play/Pause

            Button {
                viewModel.send(.playState(.playPause))
            } label: {
                Image(systemName: session.playState?.isPaused == true ? "play.fill" : "pause.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
                    .frame(width: 60, height: 60)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .disabled(!canControlMedia)
            .opacity(canControlMedia ? 1.0 : 0.5)

            // MARK: Next Track

            controlButton(
                systemName: "forward.end.alt.fill",
                action: { viewModel.send(.playState(.nextTrack)) },
                enabled: canControlMedia
            )

            // MARK: Forward 30s

            controlButton(
                systemName: "goforward.30",
                action: { seekRelative(300_000_000) },
                enabled: canSeek
            )
        }
        .padding(.vertical, 20)
    }

    // MARK: Bottom Controls Section

    private var bottomControlsSection: some View {
        VStack(spacing: 20) {

            if session.nowPlayingItem != nil {
                // MARK: Media Controls - Shuffle and Repeat

                HStack(spacing: 40) {

                    Button {
                        let isCurrentlyShuffled = session.playState?.playbackOrder == PlaybackOrder.shuffle
                        viewModel.send(.command(.setShuffleQueue, .shuffleMode(!isCurrentlyShuffled)))
                    } label: {
                        Image(systemName: "shuffle")
                            .font(.title3)
                            .foregroundColor(session.playState?.playbackOrder == PlaybackOrder.shuffle ? .accentColor : .white)
                    }

                    Spacer()

                    Button {
                        isKeyboardPresented = true
                    } label: {
                        Image(systemName: "keyboard")
                            .font(.title3)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Button {
                        cycleRepeatMode()
                    } label: {
                        Image(systemName: repeatModeIcon)
                            .font(.title3)
                            .foregroundColor(session.playState?.repeatMode != .repeatNone ? .accentColor : .white)
                    }
                }

                // MARK: Volume Control

                HStack(spacing: 16) {
                    Image(systemName: session.playState?.isMuted == true ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.caption)
                        .foregroundColor(.white)

                    Slider(progress: volumeProgress)
                        .tint(.white)
                        .onChange(of: volumeLevel) { newValue in
                            let volume = Int(newValue)
                            viewModel.send(.command(.setVolume, .volume(volume)))
                            box.value?.playState?.volumeLevel = volume
                        }

                    Button {
                        if session.playState?.isMuted == true {
                            viewModel.send(.command(.unmute))
                        } else {
                            viewModel.send(.command(.mute))
                        }
                    } label: {
                        Image(systemName: session.playState?.isMuted == true ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)

            } else {
                // MARK: Navigation Controls

                HStack(spacing: 40) {

                    dPadButton(systemName: "magnifyingglass", command: .goToSearch)

                    Spacer()

                    Button {
                        isKeyboardPresented = true
                    } label: {
                        Image(systemName: "keyboard")
                            .font(.title3)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    dPadButton(systemName: "gearshape.fill", command: .goToSettings)
                }
            }
        }
    }

    // MARK: Keyboard Sheet

    private var keyboardSheet: some View {
        NavigationStack {
            VStack {
                TextField("Enter text", text: $keyboardInput)
                    .padding()
                    .textFieldStyle(.roundedBorder)

                Spacer()
            }
            .navigationTitle("Send Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isKeyboardPresented = false
                        keyboardInput = ""
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        isKeyboardPresented = false
                    }
                    .disabled(keyboardInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
        }
        .presentationDetents([.medium])
    }

    // MARK: Helper Views

    private func controlButton(systemName: String, action: @escaping () -> Void, enabled: Bool) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
        }
        .disabled(!enabled)
        .opacity(enabled ? 1.0 : 0.5)
    }

    private func dPadButton(systemName: String, command: GeneralCommandType) -> some View {
        let enabled = session.supportedCommands?.contains(command) == true
        return Button {
            viewModel.send(.command(command))
        } label: {
            Image(systemName: systemName)
                .font(.title2)
                .foregroundColor(enabled ? .white : .gray)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(enabled ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
                )
        }
        .disabled(!enabled)
    }

    // MARK: Helper Properties

    private var canControlMedia: Bool {
        session.isSupportsMediaControl == true
    }

    private var canSeek: Bool {
        canControlMedia && session.nowPlayingItem != nil
    }

    private var progressValue: Double {
        guard let position = session.playState?.positionTicks,
              let duration = session.nowPlayingItem?.runTimeTicks,
              duration > 0 else { return 0.0 }
        return Double(position) / Double(duration)
    }

    private var repeatModeIcon: String {
        switch session.playState?.repeatMode {
        case .repeatOne:
            return "repeat.1"
        case .repeatAll:
            return "repeat"
        default:
            return "repeat"
        }
    }

    private var volumeProgress: Binding<CGFloat> {
        Binding(
            get: { CGFloat(self.volumeLevel / 100.0) },
            set: { newValue in
                self.volumeLevel = Double(newValue * 100.0)
            }
        )
    }

    // MARK: Helper Methods

    private func formatTime(_ ticks: Int64?) -> String {
        guard let ticks = ticks else { return "0:00" }
        let seconds = Int(ticks / 10_000_000)
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    private func seekRelative(_ deltaTicks: Int64) {
        guard let currentPosition = session.playState?.positionTicks,
              let duration = session.nowPlayingItem?.runTimeTicks,
              duration > 0 else { return }

        let newPosition = max(Int64(0), Int64(currentPosition) + deltaTicks)

        viewModel.send(.seek(positionTicks: newPosition))
    }

    private func toggleFavorite() {
        // This would need to be implemented based on your Jellyfin API
        // viewModel.send(.command(.toggleFavorite))
    }

    private func cycleRepeatMode() {
        let currentMode = session.playState?.repeatMode ?? .repeatNone
        let nextMode: RepeatMode = switch currentMode {
        case .repeatNone:
            .repeatAll
        case .repeatAll:
            .repeatOne
        case .repeatOne:
            .repeatNone
        default:
            .repeatAll
        }
        viewModel.send(.command(.setRepeatMode, .repeatMode(nextMode)))
    }

    // MARK: Keyboard Input

    private func sendKeyboardInput() {
        let trimmed = keyboardInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              session.supportedCommands?.contains(.sendString) == true else { return }

        viewModel.send(.command(.sendString, .string(trimmed)))

        if session.supportedCommands?.contains(.sendKey) == true {
            viewModel.send(.command(.sendKey, .key("Enter")))
        }

        keyboardInput = ""
    }
}
