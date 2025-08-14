//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

// TODO: behavioral implementations
//       - PiP

/// The proxy for top-down communication to an
/// underlying media player
protocol MediaPlayerProxy: ObservableObject, MediaPlayerObserver {

    associatedtype VideoPlayerBody: View = EmptyView

    func play()
    func pause()
    func stop()

    func jumpForward(_ seconds: Duration)
    func jumpBackward(_ seconds: Duration)
    func setRate(_ rate: Float)
    func setSeconds(_ seconds: Duration)

    func setAudioStream(_ stream: MediaStream)
    func setSubtitleStream(_ stream: MediaStream)

    func setAspectFill(_ aspectFill: Bool)

    @ViewBuilder
    @MainActor
    func makeVideoPlayerBody() -> VideoPlayerBody
}

extension MediaPlayerProxy where VideoPlayerBody == EmptyView {
    func makeVideoPlayerBody() -> VideoPlayerBody {
        EmptyView()
    }
}

protocol MediaPlayerOffsetConfigurable {
    func setAudioOffset(_ seconds: Duration)
    func setSubtitleOffset(_ seconds: Duration)
}

protocol MediaPlayerSubtitleConfigurable {
    func setSubtitleColor(_ color: Color)
    func setSubtitleFontName(_ fontName: String)
    func setSubtitleFontSize(_ fontSize: Int)
}
