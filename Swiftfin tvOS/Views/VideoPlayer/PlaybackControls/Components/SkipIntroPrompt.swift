//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    struct SkipIntroPrompt: View {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @FocusState
        private var isFocused: Bool

        @ObservedObject
        var prompt: IntroSkipPrompt

        private var isVisible: Bool {
            containerState.isPresentingIntroSkipPrompt
        }

        private func skipIntro() {
            guard let target = prompt.target else { return }
            manager.seek(to: target)
        }

        var body: some View {
            Button(action: skipIntro) {
                Label(L10n.skipIntro, systemImage: VideoPlayerActionButton.nextChapter.systemImage)
            }
            .buttonStyle(PromptButtonStyle())
            .focused($isFocused)
            .disabled(!isVisible)
            .isVisible(isVisible)
            .scaleEffect(isVisible ? 1 : 0.9)
            .animation(.easeInOut(duration: 0.25), value: isVisible)
            .onChange(of: isVisible) {
                if isVisible {
                    isFocused = true
                }
            }
            .onReceive(manager.secondsBox.$value) { seconds in
                prompt.update(
                    itemID: manager.item.id,
                    navigator: manager.chapterNavigator,
                    seconds: seconds
                )
            }
        }
    }

    private struct PromptButtonStyle: ButtonStyle {

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.black)
                .padding(.horizontal, 32)
                .padding(.vertical, 18)
                .background(.white, in: Capsule())
                .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
                .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
        }
    }
}
