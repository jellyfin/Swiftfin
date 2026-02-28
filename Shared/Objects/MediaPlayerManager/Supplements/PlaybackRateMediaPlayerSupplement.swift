//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: POC of a "guest" supplement, finish
//       - make general for basic increment/decrement controls
//       - audio/subtitle offset
struct PlaybackRateMediaPlayerSupplement: MediaPlayerSupplement {

    let displayTitle: String = "Playback Rate"
    let id: String = "Playback Rate"

    var videoPlayerBody: some PlatformView {
        PlaybackRateOverlay()
    }

    struct PlaybackRateOverlay: PlatformView {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @ViewBuilder
        private var compactView: some View {
            VStack {

                Text(manager.rate, format: .playbackRate)
                    .font(.largeTitle)

                HStack {
                    Button {
                        manager.setRate(rate: manager.rate + 0.05)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7)
                                .foregroundStyle(.white)

                            Text("+")
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Button {
                        manager.setRate(rate: manager.rate - 0.05)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7)
                                .foregroundStyle(.white)

                            Text("-")
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 40)
            }
        }

        @ViewBuilder
        private var regularView: some View {}

        var iOSView: some View {
            CompactOrRegularView(
                isCompact: containerState.isCompact
            ) {
                compactView
            } regularView: {
                Color.orange
                    .opacity(0.5)
            }
        }

        // TODO: Localize
        var tvOSView: some View {
            VStack(spacing: 30) {
                Text("Playback Rate")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(manager.rate, format: .playbackRate)
                    .font(.system(size: 120))
                    .fontWeight(.bold)

                HStack(spacing: 20) {
                    Button {
                        let newRate = clamp(manager.rate - 0.05, min: 0.5, max: 2.0)
                        manager.setRate(rate: newRate)
                    } label: {
                        Label("Decrease", systemImage: "minus")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(width: 140, height: 100)
                    }
                    .buttonStyle(.card)

                    Button {
                        let newRate = clamp(manager.rate + 0.05, min: 0.5, max: 2.0)
                        manager.setRate(rate: newRate)
                    } label: {
                        Label("Increase", systemImage: "plus")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(width: 140, height: 100)
                    }
                    .buttonStyle(.card)
                }
            }
            .padding(40)
        }
    }
}
