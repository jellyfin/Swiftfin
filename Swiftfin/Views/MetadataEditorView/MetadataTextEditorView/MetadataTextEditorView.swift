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

struct MetadataTextEditorView: View {

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @State
    private var tempItem: BaseItemDto

    @ObservedObject
    private var viewModel: UpdateMetadataViewModel

    private let itemType: BaseItemKind

    init(item: BaseItemDto) {
        self.itemType = item.type!
        self.viewModel = UpdateMetadataViewModel(item: item)
        _tempItem = State(initialValue: item)
    }

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        contentView
            .navigationBarTitle("Edit Metadata", displayMode: .inline)
            .topBarTrailing {
                Button(L10n.save) {
                    viewModel.send(.update(tempItem))
                }
                .buttonStyle(.toolbarPill)
                .disabled(viewModel.item == tempItem)
            }
            .navigationBarCloseButton {
                router.dismissCoordinator()
            }
    }

    @ViewBuilder
    private var contentView: some View {
        switch itemType {
        case .movie:
            movieView
        case .series:
            movieView
        case .season:
            movieView
        case .episode:
            movieView
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var movieView: some View {
        Form {
            TitleSection(
                item: $tempItem,
                itemType: itemType
            )

            DatesSection(
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

            AssociationsSection(item: $tempItem)

            LocalizationSection(item: $tempItem)

            LockMetadataSection(item: $tempItem)
        }
    }
}
