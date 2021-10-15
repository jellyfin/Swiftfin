/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Introspect
import JellyfinAPI
import SwiftUI

class VideoPlayerItem: ObservableObject {
    @Published var shouldShowPlayer: Bool = false
    @Published var itemToPlay = BaseItemDto()
}

// Intermediary view for ItemView to set navigation bar settings
struct ItemNavigationView: View {
    private let item: BaseItemDto

    init(item: BaseItemDto) {
        self.item = item
    }

    var body: some View {
        ItemView(item: item)
            .navigationBarTitle("", displayMode: .inline)
    }
}

fileprivate struct ItemView: View {
    @EnvironmentObject var itemRouter: ItemCoordinator.Router

    @State private var videoIsLoading: Bool = false // This variable is only changed by the underlying VLC view.
    @State private var viewDidLoad: Bool = false
    @State private var orientation: UIDeviceOrientation = .unknown
    @StateObject private var videoPlayerItem = VideoPlayerItem()
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass

    private let viewModel: ItemViewModel

    init(item: BaseItemDto) {
        switch item.itemType {
        case .movie:
            self.viewModel = MovieItemViewModel(item: item)
        case .season:
            self.viewModel = SeasonItemViewModel(item: item)
        case .episode:
            self.viewModel = EpisodeItemViewModel(item: item)
        case .series:
            self.viewModel = SeriesItemViewModel(item: item)
        default:
            self.viewModel = ItemViewModel(item: item)
        }
    }

    @ViewBuilder
    var toolbarItemContent: some View {
        switch viewModel.item.itemType {
        case .season:
            Menu {
                Button {
                    (viewModel as? SeasonItemViewModel)?.routeToSeriesItem()
                } label: {
                    Label("Show Series", systemImage: "text.below.photo")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        case .episode:
            Menu {
                Button {
                    (viewModel as? EpisodeItemViewModel)?.routeToSeriesItem()
                } label: {
                    Label("Show Series", systemImage: "text.below.photo")
                }
                Button {
                    (viewModel as? EpisodeItemViewModel)?.routeToSeasonItem()
                } label: {
                    Label("Show Season", systemImage: "square.fill.text.grid.1x2")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        default:
            EmptyView()
        }
    }

    var body: some View {
        Group {
            if hSizeClass == .compact && vSizeClass == .regular {
                ItemPortraitMainView(videoIsLoading: $videoIsLoading)
                    .environmentObject(videoPlayerItem)
                    .environmentObject(viewModel)
            } else {
                ItemLandscapeMainView(videoIsLoading: $videoIsLoading)
                    .environmentObject(videoPlayerItem)
                    .environmentObject(viewModel)
            }
        }
        .onReceive(videoPlayerItem.$shouldShowPlayer) { flag in
            guard flag else { return }
            self.itemRouter.route(to: \.videoPlayer, viewModel.item)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                toolbarItemContent
            }
        }
    }
}
