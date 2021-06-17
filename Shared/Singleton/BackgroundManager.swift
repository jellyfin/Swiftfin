//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation

final class BackgroundManager {
    static let current = BackgroundManager()
    fileprivate(set) var backgroundURL: URL?
    fileprivate(set) var blurhash: String = "001fC^"

    init() {
        backgroundURL = nil
    }

    func setBackground(to: URL, hash: String) {
        self.backgroundURL = to
        self.blurhash = hash
        
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("backgroundDidChange"), object: nil)
    }
    
    func clearBackground() {
        self.backgroundURL = nil
        self.blurhash = "001fC^"
        
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("backgroundDidChange"), object: nil)
    }
}

