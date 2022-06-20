//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Introspect
import JellyfinAPI
import SwiftUI
import WidgetKit

struct ItemView: View {

	private let item: BaseItemDto
    private let viewModel: ItemViewModel
    
    init(item: BaseItemDto) {
        self.item = item
        
        switch item.type ?? .none {
        case .movie:
            viewModel = MovieItemViewModel(item: item)
        case .series:
            viewModel = SeriesItemViewModel(item: item)
        case .season:
            viewModel = SeasonItemViewModel(item: item)
        case .episode:
            viewModel = EpisodeItemViewModel(item: item)
        default:
            fatalError()
        }
    }

	var body: some View {
        Group {
            switch item.type {
            case .movie:
                if UIDevice.isIPad {
                    iPadOSMovieItemView()
                } else {
                    MovieItemView()
                }
            case .series:
                if UIDevice.isIPad {
                    iPadOSSeriesItemView()
                } else {
                    SeriesItemView()
                }
            case .season:
                SeasonItemView()
            case .episode:
                EpisodeItemView()
            default:
                Text("N/A")
            }
        }
        .environmentObject(viewModel)
	}
}
