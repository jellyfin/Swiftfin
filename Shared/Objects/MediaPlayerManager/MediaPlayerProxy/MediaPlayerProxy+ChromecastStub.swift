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

// MARK: - Phase 1 stub (no Cast LOAD / session UI)

/// Records transport calls from `MediaPlayerManager` for tests and DEBUG wiring.
/// Real Chromecast commands are implemented in later phases.
@MainActor
final class ChromecastStubVideoMediaPlayerProxy: VideoMediaPlayerProxy {

    typealias VideoPlayerBody = ChromecastStubVideoPlaceHolder

    let isBuffering: PublishedBox<Bool> = .init(initialValue: false)
    let videoSize: PublishedBox<CGSize> = .init(initialValue: .zero)

    weak var manager: MediaPlayerManager?

    /// Ordered record of proxy entry points invoked (for unit tests).
    private(set) var recordedInvocations: [String] = []

    private func record(_ name: String) {
        recordedInvocations.append(name)
    }

    /// Resets the invocation log (e.g. between tests).
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

    func setSeconds(_ seconds: Duration) {
        record("setSeconds")
    }

    func setAspectFill(_ aspectFill: Bool) {
        record("setAspectFill(\(aspectFill)")
    }

    func setAudioStream(_ stream: MediaStream) {
        record("setAudioStream")
    }

    func setSubtitleStream(_ stream: MediaStream) {
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
                #if DEBUG
                Text("Cast stub")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                #endif
            }
    }
}
