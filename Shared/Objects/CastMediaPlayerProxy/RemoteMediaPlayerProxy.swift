//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

@MainActor
protocol RemoteMediaPlayerProxy: ObservableObject {

    var activeItem: BaseItemDto? { get }
    var hasStarted: Bool { get }
    var isPaused: Bool { get }
    var seconds: Duration { get }
    var selectedAudioStreamIndex: Int { get }
    var selectedSubtitleStreamIndex: Int { get }

    func play()
    func pause()
    func stop()

    func jumpForward(_ seconds: Duration)
    func jumpBackward(_ seconds: Duration)
    func setSeconds(_ seconds: Duration)
}

@MainActor
protocol MediaPlayerVolumeConfigurable {

    var isMuted: Bool { get }
    var volumeLevel: Int { get }

    func setVolume(_ level: Int)
    func toggleMute()
}

@MainActor
protocol MediaPlayerQueueConfigurable {

    var queueCount: Int { get }
    var queueIndex: Int? { get }
    var queueItems: [BaseItemDto] { get }

    func nextItem()
    func playQueueItem(_ item: BaseItemDto)
    func previousItem()
}
