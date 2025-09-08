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

struct VideoPlayer: View {

    @Default(.VideoPlayer.Subtitle.subtitleColor)
    private var subtitleColor
    @Default(.VideoPlayer.Subtitle.subtitleFontName)
    private var subtitleFontName
    @Default(.VideoPlayer.Subtitle.subtitleSize)
    private var subtitleSize

    @EnvironmentObject
    private var toastProxy: ToastProxy

    @LazyState
    private var proxy: any VideoMediaPlayerProxy

    @ObservedObject
    private var manager: MediaPlayerManager

    @Router
    private var router

    @State
    private var audioOffset: Duration = .zero
    @State
    private var isGestureLocked: Bool = false
    @State
    private var scrubbingStartDate: Date? = nil
    @State
    private var subtitleOffset: Duration = .zero

    @StateObject
    private var containerState: VideoPlayerContainerState = .init()

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
    private var containerView: some View {
        VideoPlayerContainerView(
            containerState: containerState,
            manager: manager
        ) {
            proxy.videoPlayerBody
                .eraseToAnyView()
        } playbackControls: {
            PlaybackControls()
        }
        .environment(\.audioOffset, $audioOffset)
        .environment(\.isGestureLocked, $isGestureLocked)
    }

    var body: some View {
        containerView
            .backport
            .onChange(of: audioOffset) { _, newValue in
                if let proxy = proxy as? MediaPlayerOffsetConfigurable {
                    proxy.setAudioOffset(newValue)
                }
            }
            .backport
            .onChange(of: containerState.isAspectFilled) { _, newValue in
                UIView.animate(withDuration: 0.2) {
                    proxy.setAspectFill(newValue)
                }
            }
            .backport
            .onChange(of: containerState.isScrubbing) { _, newValue in
                if newValue { scrubbingStartDate = .now }

                guard let scrubbingStartDate else { return }
                let scrubbingDelta = Date.now.timeIntervalSince(scrubbingStartDate)
                let secondsDelta = abs(manager.seconds - containerState.scrubbedSeconds.value)

                guard secondsDelta >= .seconds(1), scrubbingDelta >= 0.1 else { return }

                let scrubbedSeconds = containerState.scrubbedSeconds.value
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
                containerState.isAspectFilled = false
                audioOffset = .zero
                subtitleOffset = .zero

                // TODO: move to container view
                containerState.scrubbedSeconds.value = newItem?.baseItem.startSeconds ?? .zero
            }
            .onReceive(manager.$state) { newState in
                if newState == .stopped {
                    proxy.stop()
                    router.dismiss()
                }
            }
    }
}

@inlinable
func abs(_ d: Duration) -> Duration {
    d < .zero ? (.zero - d) : d
}
