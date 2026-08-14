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
        @ObservedObject
        var target: SessionViewModel

        let supportedCommands: [GeneralCommandType]
        let perform: (() -> Void) -> Void
        let onMenuPressed: (Bool) -> Void

        @State
        private var isAdjustingVolume = false
        @State
        private var volume: Double = 100

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
        private var volumeSlider: some View {
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

        @ViewBuilder
        private var queueMenu: some View {
            Menu {
                ForEach(proxy.queueItems, id: \.id) { queueItem in
                    Button {
                        perform { proxy.playQueueItem(queueItem) }
                    } label: {
                        if queueItem.id == proxy.displayedItem?.id {
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
            .buttonStyle(.isPressed(onMenuPressed))
        }

        var body: some View {
            HStack(spacing: 16) {
                if supportedCommands.contains(.toggleMute) {
                    muteButton
                }

                if supportedCommands.contains(.setVolume) {
                    volumeSlider
                }

                if proxy.queueItems.isNotEmpty {
                    queueMenu
                }
            }
            .onAppear {
                if let volumeLevel = target.session.playState?.volumeLevel {
                    volume = Double(volumeLevel)
                }
            }
        }
    }
}
