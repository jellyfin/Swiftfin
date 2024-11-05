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

    init(item: BaseItemDto) {
        self._item = State(initialValue: item)
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(L10n.item)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismissCoordinator()
            }
            .onNotification(.itemMetadataDidChange) { notification in
                guard let updatedItem = notification.object as? BaseItemDto else { return }
                item = updatedItem
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

            if item.canDelete ?? false {
                Section {
                    DeleteItemButton(item: item) {
                        router.dismissCoordinator()
                    }
                }
            }

            Section(L10n.advanced) {
                ChevronButton(L10n.metadata)
                    .onSelect {
                        router.route(to: \.editMetadata)
                    }
            }
        }
    }
}
