//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension HorizontalAlignment {

    struct VideoPlayerTitleAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[HorizontalAlignment.leading]
        }
    }

    static let VideoPlayerTitleAlignmentGuide = HorizontalAlignment(VideoPlayerTitleAlignment.self)

    struct LibraryRowContentAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[HorizontalAlignment.leading]
        }
    }

    static let LeadingLibraryRowContentAlignmentGuide = HorizontalAlignment(LibraryRowContentAlignment.self)
}
