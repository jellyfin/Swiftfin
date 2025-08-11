//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import PreferencesView
import SwiftUI
import VLCUI

// TODO: decouple from VLC, just use manager's proxy

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

    @StateObject
    private var proxy: AnyMediaPlayerProxy

    // MARK: init

    init(manager: MediaPlayerManager) {
        self._proxy = StateObject(wrappedValue: {
//            let actualProxy = VLCMediaPlayerProxy()
            let actualProxy = AVPlayerMediaPlayerProxy()
            let anyProxy = AnyMediaPlayerProxy(actualProxy)
            manager.proxy = anyProxy
            return anyProxy
        }())

        self.manager = manager
    }

    // MARK: playerView

    @ViewBuilder
    private var playerView: some View {
        ZStack {

            Color.black

            proxy.makeVideoPlayerBody(manager: manager)

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
            .onChange(of: audioOffset) { _ in
//                vlcUIProxy.setAudioDelay(newValue)
            }
            .onChange(of: isAspectFilled) { newValue in
                UIView.animate(withDuration: 0.2) {
                    proxy.setAspectFill(newValue)
                }
            }
            .onChange(of: isScrubbing) { isScrubbing in
                guard !isScrubbing else { return }

                manager.seconds = scrubbedSeconds
                proxy.setSeconds(scrubbedSeconds)
            }
            .onChange(of: subtitleColor) { _ in
//                vlcUIProxy.setSubtitleColor(.absolute(newValue.uiColor))
            }
            .onChange(of: subtitleFontName) { _ in
//                vlcUIProxy.setSubtitleFont(newValue)
            }
            .onChange(of: subtitleOffset) { _ in
//                vlcUIProxy.setSubtitleDelay(newValue)
            }
            .onChange(of: subtitleSize) { _ in
//                vlcUIProxy.setSubtitleSize(.absolute(25 - newValue))
            }
            .onReceive(manager.events) { @MainActor event in
                switch event {
                case .playbackStopped:
                    proxy.stop()
                    router.dismiss()
                case let .itemChanged(playbackItem: item):
                    isAspectFilled = false
                    audioOffset = .zero
                    subtitleOffset = .zero

                    scrubbedSeconds = item.baseItem.startSeconds ?? .zero
                }
            }
    }
}
