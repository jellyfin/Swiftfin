//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: try to make views simpler so there isn't one per media type, but per view type
//       - basic (episodes, collection) vs more fancy (rest)
//       - think about future for other media types

struct OfflineItemView: View {

    @ObservedObject
    var offlineViewModel: OfflineViewModel
    @StateObject
    private var viewModel: OfflineItemViewModel

    private static func typeViewModel(for item: BaseItemDto) -> OfflineItemViewModel {
        switch item.type {
        case .episode:
            return OfflineEpisodeItemViewModel(item: item)
        case .movie:
            return OfflineMovieItemViewModel(item: item)
        case .series:
            return OfflineSeriesItemViewModel(item: item)
        default:
            assertionFailure("Unsupported item")
            return OfflineItemViewModel(item: item)
        }
    }

    init(item: BaseItemDto, offlineModel: OfflineViewModel) {
        self._viewModel = StateObject(wrappedValue: Self.typeViewModel(for: item))
        self.offlineViewModel = offlineModel
    }

    @ViewBuilder
    private var padView: some View {
        switch viewModel.item.type {
        case .episode:
            OfflineiPadOSEpisodeItemView(offlineViewModel: offlineViewModel, viewModel: viewModel as! OfflineEpisodeItemViewModel)
        case .movie:
            OfflineiPadOSMovieItemView(offlineViewModel: offlineViewModel, viewModel: viewModel as! OfflineMovieItemViewModel)
        case .series:
            OfflineiPadOSSeriesItemView(offlineViewModel: offlineViewModel, viewModel: viewModel as! OfflineSeriesItemViewModel)
        default:
            Text(L10n.notImplementedYetWithType(viewModel.item.type ?? "--"))
        }
    }

    @ViewBuilder
    private var phoneView: some View {
        switch viewModel.item.type {
        case .episode:
            OfflineEpisodeItemView(offlineViewModel: offlineViewModel, viewModel: viewModel as! OfflineEpisodeItemViewModel)
        case .movie:
            OfflineMovieItemView(offlineViewModel: offlineViewModel, viewModel: viewModel as! OfflineMovieItemViewModel)
        case .series:
            OfflineSeriesItemView(offlineViewModel: offlineViewModel, viewModel: viewModel as! OfflineSeriesItemViewModel)
        default:
            Text(L10n.notImplementedYetWithType(viewModel.item.type ?? "--"))
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if UIDevice.isPad {
            padView
        } else {
            phoneView
        }
    }

    var body: some View {
        WrappedView {
            switch viewModel.state {
            case .content:
                contentView
                    .navigationTitle(viewModel.item.displayTitle)
            case let .error(error):
                ErrorView(error: error)
            case .initial, .refreshing:
                DelayedProgressView()
            }
        }
        .transition(.opacity.animation(.linear(duration: 0.2)))
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear {
            viewModel.send(.refresh)
        }
        .topBarTrailing {
            if viewModel.backgroundStates.contains(.refresh) {
                ProgressView()
            }
        }
    }
}
