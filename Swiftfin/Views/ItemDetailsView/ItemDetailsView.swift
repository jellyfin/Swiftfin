//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemDetailsView: View {

    @EnvironmentObject
    private var router: ItemDetailsCoordinator.Router

    @State
    var item: BaseItemDto

    // MARK: - Body

    var body: some View {
        contentView
            .navigationBarTitle(L10n.item)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismissCoordinator()
            }
            .onNotification(.itemMetadataDidChange) { notification in
                guard let newItem = notification.object as? BaseItemDto else { return }
                item = newItem
            }
            .onNotification(.didDeleteItem) { _ in
                router.dismissCoordinator()
            }
    }

    // MARK: - Content View

    private var contentView: some View {
        List {
            ListTitleSection(
                item.name ?? L10n.unknown,
                description: item.path
            )

            Section {
                RefreshMetadataButton(item: item)
                    .foregroundStyle(.primary, .secondary)
            }

            if item.canDelete ?? false == false {
                Section {
                    DeleteItemButton(item: item) {
                        router.dismissCoordinator()
                    }
                }
            }

            Section(L10n.advanced) {
                ChevronButton(L10n.metadata)
                    .onSelect {
                        router.route(to: \.editMetadata, ItemDetailsViewModel(item: item))
                    }
                ChevronButton(L10n.genres)
                    .onSelect {
                        router.route(to: \.editGenres, ItemDetailsViewModel(item: item))
                    }
                ChevronButton(L10n.people)
                    .onSelect {
                        router.route(to: \.editPeople, ItemDetailsViewModel(item: item))
                    }
                ChevronButton(L10n.studios)
                    .onSelect {
                        router.route(to: \.editStudios, ItemDetailsViewModel(item: item))
                    }
                ChevronButton(L10n.tags)
                    .onSelect {
                        router.route(to: \.editTags, ItemDetailsViewModel(item: item))
                    }
            }
        }
    }
}
