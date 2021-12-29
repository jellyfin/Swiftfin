//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI

protocol VideoPlayerOverlay: View {
    var viewModel: VideoPlayerViewModel { get set }
}

extension HorizontalAlignment {

    private struct EpisodeSeriesTitleAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[HorizontalAlignment.leading]
        }
    }

    static let EpisodeSeriesAlignmentGuide = HorizontalAlignment(EpisodeSeriesTitleAlignment.self)

}
