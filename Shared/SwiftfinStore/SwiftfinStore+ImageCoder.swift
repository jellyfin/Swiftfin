//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Foundation
import UIKit

extension SwiftfinStore {

    struct ImageCoder: FieldCoderType {

        static func encodeToStoredData(_ fieldValue: UIImage?) -> Data? {
            fieldValue?.pngData()
        }

        static func decodeFromStoredData(_ data: Data?) -> UIImage? {
            guard let data else { return nil }
            return UIImage(data: data)
        }
    }
}
