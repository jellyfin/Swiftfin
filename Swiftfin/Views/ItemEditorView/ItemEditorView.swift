//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

struct ItemEditorView: View {

    @Injected(\.currentUserSession)
    private var userSession

    @EnvironmentObject
    private var router: ItemEditorCoordinator.Router

    @State
    var item: BaseItemDto

    // MARK: - Body

    var body: some View {
        contentView
            .navigationBarTitle(L10n.editItem)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismissCoordinator()
            }
            .topBarTrailing {
                DeleteItemButton(item: item) {
                    router.dismissCoordinator()
                }
                .environment(\.isEnabled, item.canDelete ?? false && StoredValues[.User.enableItemDeletion])
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
                    .environment(\.isEnabled, userSession?.user.isAdministrator ?? false)
            }
        }
    }
}
