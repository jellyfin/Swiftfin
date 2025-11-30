//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension VideoPlayer.PlaybackControls {

    struct SkipIntroButton: View {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var activeSeconds: Duration = .zero
        @State
        private var hasInitialized: Bool = false

        private var shouldShowButton: Bool {
            // Don't show until we've received at least one playback position update
            guard hasInitialized else { return false }

            guard let introSegment = manager.introSegment,
                  let startTicks = introSegment.startTicks,
                  let endTicks = introSegment.endTicks
            else {
                return false
            }

            let currentTicks = activeSeconds.ticks
            return currentTicks >= startTicks && currentTicks < endTicks
        }

        private func skipIntro() {
            guard let introSegment = manager.introSegment,
                  let endTicks = introSegment.endTicks else { return }
            let endTime = Duration.ticks(endTicks)
            manager.proxy?.setSeconds(endTime)
            manager.setPlaybackRequestStatus(status: .playing)
        }

        private var bottomPadding: CGFloat {
            if containerState.isPresentingOverlay {
                // Move button up slightly when controls are visible to avoid overlap
                return safeAreaInsets.bottom + 100
            } else {
                // Sit right at the bottom when controls are hidden
                return safeAreaInsets.bottom + 16
            }
        }

        var body: some View {
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    if shouldShowButton {
                        Button(action: skipIntro) {
                            Text(L10n.skipIntro)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 16)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                }
                .padding(.trailing, safeAreaInsets.trailing + 48)
                .padding(.bottom, bottomPadding)
            }
            .animation(.easeInOut(duration: 0.3), value: shouldShowButton)
            .animation(.easeInOut(duration: 0.3), value: containerState.isPresentingOverlay)
            .assign(manager.secondsBox.$value, to: $activeSeconds)
            .onChange(of: activeSeconds) { _ in
                // Mark as initialized after first playback position update
                if !hasInitialized {
                    hasInitialized = true
                }
            }
        }
    }
}
