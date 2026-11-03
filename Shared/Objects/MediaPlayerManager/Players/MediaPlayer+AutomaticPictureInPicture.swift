//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation

#if os(iOS)
extension MediaPlayerPictureInPictureProviding {

    /// Retain the token for the player's lifetime, including when no item is loaded.
    func observeAutomaticPictureInPicture() -> AnyCancellable {
        allowsAutomaticPiP = Defaults[.VideoPlayer.Transition.automaticPictureInPicture]

        return Defaults.publisher(.VideoPlayer.Transition.automaticPictureInPicture, options: [])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] change in
                self?.allowsAutomaticPiP = change.newValue
            }
    }
}
#endif
