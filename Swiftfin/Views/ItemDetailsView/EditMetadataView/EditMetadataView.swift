//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

struct EditMetadataView: View {

    @EnvironmentObject
    private var router: ItemDetailsCoordinator.Router

    @ObservedObject
    private var viewModel: ItemDetailsViewModel

    @Binding
    var item: BaseItemDto

    @State
    private var tempItem: BaseItemDto

    private let itemType: BaseItemKind

    // MARK: - Initializer

    init(viewModel: ItemDetailsViewModel) {
        self.viewModel = viewModel
        self._item = Binding(get: { viewModel.item }, set: { viewModel.item = $0 })
        self._tempItem = State(initialValue: viewModel.item)
        self.itemType = viewModel.item.type!
    }

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        contentView
            .navigationBarTitle(L10n.editWithItem(L10n.metadata))
            .navigationBarTitleDisplayMode(.inline)
            .topBarTrailing {
                Button(L10n.save) {
                    item = tempItem
                    viewModel.send(.updateItem(tempItem))
                }
                .buttonStyle(.toolbarPill)
                .disabled(viewModel.item == tempItem)
            }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch itemType {
        case .movie:
            movieView
        case .series:
            seriesView
        case .episode:
            episodeView
        default:
            EmptyView()
        }
    }

    // MARK: - Movie View

    @ViewBuilder
    private var movieView: some View {
        Form {
            TitleSection(
                item: $tempItem,
                itemType: itemType
            )

            DateSection(
                item: $tempItem,
                itemType: itemType
            )

            ReviewsSection(item: $tempItem)

            OverviewSection(
                item: $tempItem,
                itemType: itemType
            )

            ParentalRatingSection(item: $tempItem)

            MediaFormatSection(
                item: $tempItem,
                itemType: itemType
            )

            LocalizationSection(item: $tempItem)

            LockMetadataSection(item: $tempItem)
        }
    }

    // MARK: - Series View

    @ViewBuilder
    private var seriesView: some View {
        Form {
            TitleSection(
                item: $tempItem,
                itemType: itemType
            )

            DateSection(
                item: $tempItem,
                itemType: itemType
            )

            SeriesSection(item: $tempItem)

            OverviewSection(
                item: $tempItem,
                itemType: itemType
            )

            ReviewsSection(item: $tempItem)

            ParentalRatingSection(item: $tempItem)

            MediaFormatSection(
                item: $tempItem,
                itemType: itemType
            )

            LocalizationSection(item: $tempItem)

            LockMetadataSection(item: $tempItem)
        }
    }

    // MARK: - Episode View

    @ViewBuilder
    private var episodeView: some View {
        Form {
            TitleSection(
                item: $tempItem,
                itemType: itemType
            )

            DateSection(
                item: $tempItem,
                itemType: itemType
            )

            EpisodeSection(item: $tempItem)

            OverviewSection(
                item: $tempItem,
                itemType: itemType
            )

            ReviewsSection(item: $tempItem)

            ParentalRatingSection(item: $tempItem)

            MediaFormatSection(
                item: $tempItem,
                itemType: itemType
            )

            LocalizationSection(item: $tempItem)

            LockMetadataSection(item: $tempItem)
        }
    }
}
