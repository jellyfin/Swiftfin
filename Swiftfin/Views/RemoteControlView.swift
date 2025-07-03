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
    private var isKeyboardPresented = false
    @State
    private var keyboardInput = ""

    private var session: SessionInfoDto {
        box.value!
    }

    init(box: BindingBox<SessionInfoDto?>) {
        self.box = box
        _viewModel = StateObject(wrappedValue: SessionManagerViewModel(box.value!))
    }

    var body: some View {
        VStack(spacing: 24) {

            Spacer(minLength: 12)

            // MARK: - D-Pad

            VStack(spacing: 12) {
                circleButton(icon: "chevron.up", command: .moveUp)

                HStack(spacing: 12) {
                    circleButton(icon: "chevron.left", command: .moveLeft)

                    Button(action: {
                        viewModel.send(.generalCommand(.sendKey, .key("Enter")))
                    }) {
                        Image(systemName: "circle")
                            .font(.title2)
                            .foregroundColor(.accentColor.overlayColor)
                            .padding(20)
                            .background(Circle().fill(Color.accentColor))
                    }

                    circleButton(icon: "chevron.right", command: .moveRight)
                }

                circleButton(icon: "chevron.down", command: .moveDown)
            }

            // MARK: - Media Controls

            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    playPauseButton()
                    volumeButton(systemName: "speaker.wave.3.fill", delta: 5)
                }

                HStack(spacing: 20) {
                    playbackButton("stop.fill") {
                        viewModel.send(.playState(.stop))
                    }
                    volumeButton(systemName: "speaker.wave.1.fill", delta: -5)
                }

                HStack(spacing: 20) {
                    iconButton("magnifyingglass", command: .goToSearch)
                    if session.playState?.isMuted == true {
                        iconButton("volume.fill", command: .unmute)
                    } else {
                        iconButton("volume.slash.fill", command: .mute)
                    }
                }
            }

            Spacer()

            // MARK: - Keyboard Button

            Button(action: { isKeyboardPresented = true }) {
                Label("Keyboard", systemImage: "keyboard")
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundColor(.accentColor.overlayColor)
                    .clipShape(Capsule())
            }

            Spacer(minLength: 20)
        }
        .padding()
        .sheet(isPresented: $isKeyboardPresented, onDismiss: sendKeyboardInput) {
            NavigationStack {
                VStack {
                    TextField("Enter text", text: $keyboardInput)
                        .padding()
                        .textFieldStyle(.roundedBorder)

                    Spacer()
                }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Submit") {
                            isKeyboardPresented = false
                        }
                    }
                }
                .padding()
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - Play/Pause

    private func playPauseButton() -> some View {
        Button(action: {
            viewModel.send(.playState(.playPause))
        }) {
            Image(systemName: session.playState?.isPaused == true ? "play.fill" : "pause.fill")
                .font(.title2)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.accentColor.overlayColor)
                .clipShape(Circle())
        }
        .disabled(session.isSupportsMediaControl == false)
    }

    // MARK: - Media Control Button

    private func playbackButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        let enabled = session.nowPlayingItem != nil
        return Button {
            action()
        } label: {
            Image(systemName: systemName)
                .font(.title2)
                .padding()
                .background(enabled ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(enabled ? .accentColor.overlayColor : .gray)
                .clipShape(Circle())
        }
        .disabled(!enabled)
    }

    // MARK: - Media Control Button

    private func mediaControlButton(_ systemName: String, command: GeneralCommandType) -> some View {
        let enabled = session.supportedCommands?.contains(command) == true
        return Button {
            viewModel.send(.command(command))
        } label: {
            Image(systemName: systemName)
                .font(.title2)
                .padding()
                .background(enabled ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(enabled ? .accentColor.overlayColor : .gray)
                .clipShape(Circle())
        }
        .disabled(!enabled)
    }

    // MARK: - Volume Controls

    private func volumeButton(systemName: String, delta: Int) -> some View {
        Button {
            guard let current = session.playState?.volumeLevel else { return }
            let newVolume = min(100, max(0, current + delta))
            viewModel.send(.generalCommand(.setVolume, .volume(newVolume)))
            box.value?.playState?.volumeLevel = newVolume
        } label: {
            Image(systemName: systemName)
                .font(.title3)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(Color.accentColor.overlayColor)
                .clipShape(Circle())
        }
    }

    // MARK: - D-Pad & Icons

    private func circleButton(icon: String, command: GeneralCommandType) -> some View {
        let enabled = session.supportedCommands?.contains(command) == true
        return Button(action: {
            viewModel.send(.command(command))
        }) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(enabled ? .accentColor.overlayColor : .gray)
                .padding(20)
                .background(
                    Circle()
                        .fill(enabled ? Color.accentColor : Color.gray.opacity(0.2))
                )
        }
        .disabled(!enabled)
    }

    private func iconButton(_ systemName: String, command: GeneralCommandType) -> some View {
        let enabled = session.supportedCommands?.contains(command) == true
        return Button(action: {
            viewModel.send(.command(command))
        }) {
            Image(systemName: systemName)
                .font(.title3)
                .padding()
                .background(enabled ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(enabled ? .accentColor.overlayColor : .gray)
                .clipShape(Circle())
        }
        .disabled(!enabled)
    }

    // MARK: - Keyboard Input

    private func sendKeyboardInput() {
        let trimmed = keyboardInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              session.supportedCommands?.contains(.sendString) == true else { return }

        viewModel.send(.generalCommand(.sendString, .string(trimmed)))

        if session.supportedCommands?.contains(.sendKey) == true {
            viewModel.send(.generalCommand(.sendKey, .key("Enter")))
        }

        keyboardInput = ""
    }
}
