//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(iOS)
import AVFAudio

@MainActor
enum AirPlayVideoRoute {

    private static var currentOutput: AVAudioSessionPortDescription? {
        AVAudioSession.sharedInstance().currentRoute.outputs.first { $0.portType == .airPlay }
    }

    static var currentID: String? {
        currentOutput?.uid
    }
}
#endif
