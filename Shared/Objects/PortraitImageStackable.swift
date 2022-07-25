//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import SwiftUI

protocol PortraitImageStackable: Identifiable {
    func imageURLConstructor(maxWidth: Int) -> URL
    var blurHash: String { get }
    var title: String { get }
    var subtitle: String? { get }
    var titleInitials: String { get }
    var showTitle: Bool { get }
}

extension PortraitImageStackable {
    var titleInitials: String {
        let initials = title.split(separator: " ").compactMap { String($0).first }
        return String(initials)
    }
}
