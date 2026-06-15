//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SeriesEpisodeContentGroup: ContentGroup, Identifiable {

    let viewModel: SeriesItemViewModel

    var id: String {
        "\(viewModel.item.id ?? "series")-episode-selector"
    }

    func body(with viewModel: SeriesItemViewModel) -> some View {
        SeriesEpisodeSelector(viewModel: viewModel)
    }
}
