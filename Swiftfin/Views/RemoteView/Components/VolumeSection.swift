//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension RemoteView {

    struct VolumeSection: View {

        @Default(.accentColor)
        private var accentColor

        @ObservedObject
        var proxy: CastMediaPlayerProxy

        private var supportedCommands: [GeneralCommandType] {
            proxy.session.supportedCommands
        }

        @State
        private var isAdjustingVolume = false
        @State
        private var volume: Double = 100

        @ViewBuilder
        private var muteButton: some View {
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

        @ViewBuilder
        private var volumeSlider: some View {
            CapsuleSlider(value: $volume, total: 100)
                .onEditingChanged { isEditing in
                    isAdjustingVolume = isEditing

                    if !isEditing {
                        proxy.setVolume(Int(volume))
                    }
                }
                .gesturePadding(20)
                .frame(height: isAdjustingVolume ? 15 : 10)
                .foregroundStyle(accentColor)
                .frame(height: 15)
                .animation(.linear(duration: 0.1), value: isAdjustingVolume)
                .onChange(of: proxy.volumeLevel) { _, newValue in
                    guard !isAdjustingVolume else { return }
                    volume = Double(newValue)
                }
        }

        var body: some View {
            HStack(spacing: 16) {
                if supportedCommands.contains(.toggleMute) {
                    muteButton
                }

                if supportedCommands.contains(.setVolume) {
                    volumeSlider
                }
            }
            .onAppear {
                volume = Double(proxy.volumeLevel)
            }
        }
    }
}
