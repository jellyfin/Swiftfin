//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

#if DEBUG

// MARK: - Phase 1 stub (no Cast LOAD / session UI)

// Records transport calls from `MediaPlayerManager` for unit tests.
// Real Chromecast commands are implemented in later phases.
@MainActor
class ChromecastStubVideoMediaPlayerProxy: VideoMediaPlayerProxy {

    typealias VideoPlayerBody = ChromecastStubVideoPlaceHolder

    let isBuffering: PublishedBox<Bool> = .init(initialValue: false)
    let videoSize: PublishedBox<CGSize> = .init(initialValue: .zero)

    weak var manager: MediaPlayerManager?

    private(set) var recordedInvocations: [String] = []

    private func record(_ name: String) {
        recordedInvocations.append(name)
    }

    func resetRecordedInvocations() {
        recordedInvocations.removeAll()
    }

    func play() {
        record("play")
    }

    func pause() {
        record("pause")
    }

    func stop() {
        record("stop")
    }

    func jumpForward(_: Duration) {
        record("jumpForward")
    }

    func jumpBackward(_: Duration) {
        record("jumpBackward")
    }

    func setRate(_: Float) {
        record("setRate")
    }

    func setSeconds(_: Duration) {
        record("setSeconds")
    }

    func setAspectFill(_ aspectFill: Bool) {
        record("setAspectFill(\(aspectFill))")
    }

    func setAudioStream(_: MediaStream) {
        record("setAudioStream")
    }

    func setSubtitleStream(_: MediaStream) {
        record("setSubtitleStream")
    }

    var videoPlayerBody: ChromecastStubVideoPlaceHolder {
        ChromecastStubVideoPlaceHolder()
    }
}

struct ChromecastStubVideoPlaceHolder: View {
    var body: some View {
        Color.black
            .overlay {
                Text("Cast stub")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
    }
}

#endif
