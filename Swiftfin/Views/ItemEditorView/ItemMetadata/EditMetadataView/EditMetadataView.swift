//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

struct EditMetadataView: View {

    // MARK: - Observed & Environment Objects

    @Router
    private var router

    @ObservedObject
    private var viewModel: ItemEditorViewModel<BaseItemDto>

    // MARK: - Metadata Variables

    @Binding
    var item: BaseItemDto

    @State
    private var tempItem: BaseItemDto

    private let itemType: BaseItemKind

    // MARK: - Initializer

    init(viewModel: ItemEditorViewModel<BaseItemDto>) {
        self.viewModel = viewModel
        self._item = Binding(get: { viewModel.item }, set: { viewModel.item = $0 })
        self._tempItem = State(initialValue: viewModel.item)
        self.itemType = viewModel.item.type!
    }

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        ZStack {
            switch viewModel.state {
            case .error:
                viewModel.error.map {
                    ErrorView(error: $0)
                }
            case .initial:
                contentView
            }
        }
        .navigationTitle(L10n.metadata)
        .navigationBarTitleDisplayMode(.inline)
        .topBarTrailing {
            if viewModel.background.states.contains(.updating) {
                ProgressView()
            }

            Button(L10n.save) {
                item = tempItem
                viewModel.update(tempItem)
                router.dismiss()
            }
            .buttonStyle(.toolbarPill)
            .disabled(viewModel.item == tempItem)
        }
        .navigationBarCloseButton {
            router.dismiss()
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated:
                UIDevice.feedback(.success)
            }
        }
        .errorMessage($viewModel.error)
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        Form {
            TitleSection(item: $tempItem)

            DateSection(
                item: $tempItem,
                itemType: itemType
            )

            if itemType == .series {
                SeriesSection(item: $tempItem)
            } else if itemType == .episode {
                EpisodeSection(item: $tempItem)
            }

            OverviewSection(
                item: $tempItem,
                itemType: itemType
            )

            ReviewsSection(item: $tempItem)

            ParentalRatingSection(item: $tempItem)

            if [.movie, .episode].contains(itemType) {
                MediaFormatSection(item: $tempItem)
            }

            LocalizationSection(item: $tempItem)

            LockMetadataSection(item: $tempItem)
        }
    }
}
