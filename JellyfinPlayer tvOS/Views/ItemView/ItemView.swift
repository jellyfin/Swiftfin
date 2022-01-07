/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Defaults
import Introspect
import JellyfinAPI
import SwiftUI

// Useless view necessary in tvOS because of iOS's implementation
struct ItemNavigationView: View {
    private let item: BaseItemDto

    init(item: BaseItemDto) {
        self.item = item
    }

    var body: some View {
        ItemView(item: item)
    }
}

struct ItemView: View {
    
    @Default(.tvOSCinematicViews) var tvOSCinematicViews
    
    private var item: BaseItemDto

    init(item: BaseItemDto) {
        self.item = item
    }

    var body: some View {
        Group {
            switch item.itemType {
            case .movie:
                if tvOSCinematicViews {
                    CinematicMovieItemView(viewModel: MovieItemViewModel(item: item))
                } else {
                    MovieItemView(viewModel: MovieItemViewModel(item: item))
                }
            case .episode:
                if tvOSCinematicViews {
                    CinematicEpisodeItemView(viewModel: EpisodeItemViewModel(item: item))
                } else {
                    EpisodeItemView(viewModel: EpisodeItemViewModel(item: item))
                }
            case .season:
                if tvOSCinematicViews {
                    CinematicSeasonItemView(viewModel: SeasonItemViewModel(item: item))
                } else {
                    SeasonItemView(viewModel: .init(item: item))
                }
            case .series:
                if tvOSCinematicViews {
                    CinematicSeriesItemView(viewModel: SeriesItemViewModel(item: item))
                } else {
                    SeriesItemView(viewModel: SeriesItemViewModel(item: item))
                }
            default:
                Text(L10n.notImplementedYetWithType(item.type ?? ""))
            }
        }
    }
}
