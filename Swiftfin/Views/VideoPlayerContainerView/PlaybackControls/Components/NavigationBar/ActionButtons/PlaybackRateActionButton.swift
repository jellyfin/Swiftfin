//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: set through proxy

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct PlaybackRateMenu: View {

        @Default(.VideoPlayer.Playback.rates)
        private var rates: [Float]

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        var body: some View {
            Menu(
                L10n.playbackSpeed,
                systemImage: "speedometer"
            ) {
                ForEach(rates, id: \.self) { rate in
                    Button {
                        manager.set(rate: rate)
                    } label: {
                        if rate == manager.rate {
                            Label("\(rate, format: .playbackRate)", systemImage: "checkmark")
                        } else {
                            Text(rate, format: .playbackRate)
                        }
                    }
                }

//                Button("Custom") {
//                    containerState.select(
//                        supplement: PlaybackRateMediaPlayerSupplement().asAny,
//                        isGuest: true
//                    )
//                }

                if !rates.contains(manager.rate) {
                    Divider()

                    Label(
                        "\(manager.rate, format: .playbackRate)",
                        systemImage: "checkmark"
                    )
                }
            }
        }
    }
}

// TODO: POC of a "guest" supplement, finish
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
                        manager.set(rate: manager.rate + 0.05)
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
                        manager.set(rate: manager.rate - 0.05)
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

        var tvOSView: some View {}
    }
}
