//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import SwiftUI

struct AVVideoPlayerView: View {

    let player: AVMediaPlayer
    let layout: VideoPlayer.VideoLayout

    var body: some View {
        PlayerSurface(player: player)
            .frame(width: layout.renderSize.width, height: layout.renderSize.height)
            .scaleEffect(layout.renderScale)
            .offset(layout.renderOffset)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
    }

    /// The engine owns the layer so playback and PiP can continue while the surface is unmounted.
    private struct PlayerSurface: UIViewRepresentable {

        let player: AVMediaPlayer

        func makeUIView(context: Context) -> SurfaceView {
            SurfaceView(player: player)
        }

        func updateUIView(_ uiView: SurfaceView, context: Context) {}
    }

    private final class SurfaceView: UIView {

        private let player: AVMediaPlayer

        init(player: AVMediaPlayer) {
            self.player = player
            super.init(frame: .zero)
            layer.addSublayer(player.playerLayer)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            player.playerLayer.frame = bounds
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()

            guard let window else { return }

            player.videoSurfaceDidMove(to: window)
        }
    }
}
