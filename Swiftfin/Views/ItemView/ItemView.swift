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

    let item: BaseItemDto

    var body: some View {
        Group {
            switch item.type {
            case .movie:
                if UIDevice.isIPad {
                    iPadOSMovieItemView(viewModel: .init(item: item))
                } else {
                    MovieItemView(viewModel: .init(item: item))
                }
            case .series:
                if UIDevice.isIPad {
                    iPadOSSeriesItemView(viewModel: .init(item: item))
                } else {
                    SeriesItemView(viewModel: .init(item: item))
                }
            case .episode:
                if UIDevice.isIPad {
                    iPadOSEpisodeItemView(viewModel: .init(item: item))
                } else {
                    EpisodeItemView(viewModel: .init(item: item))
                }
            case .boxSet:
                if UIDevice.isIPad {
                    iPadOSCollectionItemView(viewModel: .init(item: item))
                } else {
                    CollectionItemView(viewModel: .init(item: item))
                }
            case .person:
                LibraryView(viewModel: .init(person: .init(id: item.id)))
            default:
                Text(L10n.notImplementedYetWithType(item.type ?? "--"))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(item.displayName)
    }
}
