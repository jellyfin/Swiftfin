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

        @Environment(ViewState.self)
        private var viewState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @AccessibilityFocusState
        private var isAccessibilityFocused: Bool

        @State
        private var announcedSeconds: Duration = .zero

        private var isPresentingOverlay: Bool {
            viewState.presentation != .hidden
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
                        viewState.toggleControls()
                    } label: {
                        Text(L10n.video)
                    }
                    .accessibilityValue(accessibilityValue)
                    .accessibilityHint(L10n.playbackControlsAccessibilityHint)
                }
                .accessibilityFocused($isAccessibilityFocused)
                .accessibilitySortPriority(-1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .onChange(of: isPresentingOverlay) {
                    UIAccessibility.post(notification: .layoutChanged, argument: nil)

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
