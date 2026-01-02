//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import UIKit

protocol PreviewImageProvider: ObservableObject {
    func image(for seconds: Duration) async -> UIImage?
    func imageIndex(for seconds: Duration) -> Int?
}
