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

    struct VolumeSection<Proxy: MediaPlayerVolumeConfigurable & ObservableObject>: View {

        @Default(.accentColor)
        private var accentColor

        @ObservedObject
        var proxy: Proxy

        @State
        private var isAdjustingVolume = false
        @State
        private var volume: Double = 100
        @State
        private var volumeSendTask: Task<Void, Never>?

        let isMuteSupported: Bool
        let isVolumeSupported: Bool

        var body: some View {
            HStack(spacing: 16) {
                if isMuteSupported {
                    Button {
                        proxy.toggleMute()
                    } label: {
                        Image(systemName: proxy.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    }
                    .buttonStyle(.remoteControl(
                        size: .small,
                        tint: proxy.isMuted ? .secondarySystemBackground : accentColor,
                        foregroundColor: proxy.isMuted ? .primary : accentColor.overlayColor
                    ))
                }

                if isVolumeSupported {
                    CapsuleSlider(value: $volume, total: 100)
                        .onEditingChanged { isEditing in
                            isAdjustingVolume = isEditing

                            if !isEditing {
                                volumeSendTask?.cancel()
                                proxy.setVolume(Int(volume))
                            }
                        }
                        .gesturePadding(20)
                        .frame(height: isAdjustingVolume ? 15 : 10)
                        .foregroundStyle(accentColor)
                        .frame(height: 15)
                        .animation(.linear(duration: 0.1), value: isAdjustingVolume)
                        .onChange(of: volume) { _, newValue in
                            guard isAdjustingVolume else { return }

                            volumeSendTask?.cancel()
                            volumeSendTask = Task {
                                try? await Task.sleep(for: .milliseconds(500))
                                guard !Task.isCancelled else { return }

                                proxy.setVolume(Int(newValue))
                            }
                        }
                        .onChange(of: proxy.volumeLevel) { _, newValue in
                            guard !isAdjustingVolume else { return }
                            volume = Double(newValue)
                        }
                }
            }
            .onAppear {
                volume = Double(proxy.volumeLevel)
            }
        }
    }
}
