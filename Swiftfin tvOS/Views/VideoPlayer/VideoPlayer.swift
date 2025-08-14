//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

// TODO: move to Shared

struct VideoPlayer: View {

    @Default(.VideoPlayer.Subtitle.subtitleColor)
    private var subtitleColor
    @Default(.VideoPlayer.Subtitle.subtitleFontName)
    private var subtitleFontName
    @Default(.VideoPlayer.Subtitle.subtitleSize)
    private var subtitleSize

    /// The current scrubbed seconds for UI presentation and editing.
    @BoxedPublished
    private var scrubbedSeconds: Duration = .zero

    @LazyState
    private var proxy: any MediaPlayerProxy

    @ObservedObject
    private var manager: MediaPlayerManager

    @Router
    private var router

    @State
    private var audioOffset: Duration = .zero
    @State
    private var isAspectFilled: Bool = false
    @State
    private var isGestureLocked: Bool = false
    @State
    private var isScrubbing: Bool = false
    @State
    private var subtitleOffset: Duration = .zero

    init(manager: MediaPlayerManager) {
        self.manager = manager
        self._proxy = .init(wrappedValue: {
            // TODO: layer selection
            let proxy = VLCMediaPlayerProxy()
            manager.proxy = proxy
            return proxy
        }())
    }

    @ViewBuilder
    private var playerView: some View {
        ZStack {

            Color.black

            proxy.makeVideoPlayerBody()
                .eraseToAnyView()

            Overlay()
        }
        .environment(\.audioOffset, $audioOffset)
        .environment(\.isAspectFilled, $isAspectFilled)
        .environment(\.isGestureLocked, $isGestureLocked)
        .environment(\.isScrubbing, $isScrubbing)
        .environmentObject(manager)
        .environmentObject(_scrubbedSeconds.box)
    }

    var body: some View {
        playerView
            .backport
            .onChange(of: audioOffset) { _, newValue in
                if let proxy = proxy as? MediaPlayerOffsetConfigurable {
                    proxy.setAudioOffset(newValue)
                }
            }
            .backport
            .onChange(of: isAspectFilled) { _, newValue in
                UIView.animate(withDuration: 0.2) {
                    proxy.setAspectFill(newValue)
                }
            }
            .backport
            .onChange(of: isScrubbing) { _, newValue in
                guard !newValue else { return }

                manager.seconds = scrubbedSeconds
                proxy.setSeconds(scrubbedSeconds)
            }
            .backport
            .onChange(of: subtitleColor) { _, newValue in
                if let proxy = proxy as? MediaPlayerSubtitleConfigurable {
                    proxy.setSubtitleColor(newValue)
                }
            }
            .backport
            .onChange(of: subtitleFontName) { _, newValue in
                if let proxy = proxy as? MediaPlayerSubtitleConfigurable {
                    proxy.setSubtitleFontName(newValue)
                }
            }
            .backport
            .onChange(of: subtitleOffset) { _, newValue in
                if let proxy = proxy as? MediaPlayerOffsetConfigurable {
                    proxy.setSubtitleOffset(newValue)
                }
            }
            .backport
            .onChange(of: subtitleSize) { _, newValue in
                if let proxy = proxy as? MediaPlayerSubtitleConfigurable {
                    proxy.setSubtitleFontSize(newValue)
                }
            }
            .onReceive(manager.$playbackItem) { newItem in
                isAspectFilled = false
                audioOffset = .zero
                subtitleOffset = .zero

                scrubbedSeconds = newItem?.baseItem.startSeconds ?? .zero
            }
            .onReceive(manager.$state) { newState in
                if newState == .stopped {
                    proxy.stop()
                    router.dismiss()
                }
            }
    }
}
