//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer {

    struct VideoSurfaceAccessibilityView: View {

        private static let collapsedSize: CGFloat = 44

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @AccessibilityFocusState
        private var isAccessibilityFocused: Bool

        @State
        private var announcedSeconds: Duration = .zero

        private var isPresentingOverlay: Bool {
            containerState.isPresentingOverlay
        }

        private var accessibilityValue: String {
            guard let runtime = manager.item.runtime, runtime > .zero else {
                return announcedSeconds.formatted(.spokenRuntime)
            }

            return L10n.playbackPositionOfTotal(
                announcedSeconds.formatted(.spokenRuntime),
                runtime.formatted(.spokenRuntime)
            )
        }

        var body: some View {
            Rectangle()
                .hidden()
                .frame(
                    maxWidth: isPresentingOverlay ? .infinity : Self.collapsedSize,
                    maxHeight: isPresentingOverlay ? .infinity : Self.collapsedSize
                )
                .accessibilityRepresentation {
                    Button {
                        containerState.accessibilityToggleOverlay()
                    } label: {
                        Text(L10n.video)
                    }
                    .accessibilityValue(accessibilityValue)
                    .accessibilityHint(L10n.playbackControlsAccessibilityHint)
                }
                .accessibilityFocused($isAccessibilityFocused)
                .accessibilitySortPriority(-1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .onChange(of: isAccessibilityFocused) {
                    containerState.isAccessibilityFocusOnVideo = isAccessibilityFocused
                }
                .onChange(of: isPresentingOverlay) {
                    guard !isPresentingOverlay, UIAccessibility.isVoiceOverRunning else { return }
                    isAccessibilityFocused = true
                }
                .onReceive(manager.secondsBox.$value) { newValue in
                    guard !isAccessibilityFocused else { return }
                    announcedSeconds = newValue
                }
        }
    }
}
