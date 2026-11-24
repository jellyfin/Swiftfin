//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(iOS)
import AVFAudio
import Defaults

@MainActor
enum AirPlayVideoRoute {

    private static var currentOutput: AVAudioSessionPortDescription? {
        AVAudioSession.sharedInstance().currentRoute.outputs.first { $0.portType == .airPlay }
    }

    static var currentID: String? {
        currentOutput?.uid
    }

    static var isCurrentRemembered: Bool {
        guard let output = currentOutput else { return false }

        let remembered = Defaults[.Experimental.airPlayVideoRoutes]
        return remembered.contains(output.uid) || remembered.contains(output.portName)
    }

    static func rememberCurrent() {
        guard let output = currentOutput else { return }

        let entries = [output.uid, output.portName].filter { !$0.isEmpty }
        let remembered = Defaults[.Experimental.airPlayVideoRoutes]
        guard !entries.allSatisfy(remembered.contains) else { return }

        Defaults[.Experimental.airPlayVideoRoutes] = Array((remembered.filter { !entries.contains($0) } + entries).suffix(16))
    }
}
#endif
