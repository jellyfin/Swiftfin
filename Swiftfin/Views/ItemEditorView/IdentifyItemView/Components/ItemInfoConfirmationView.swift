//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemIdentifyView {

    struct ItemInfoConfirmationView: View {

        // MARK: - Item Info Variables

        let itemInfo: RemoteSearchResult
        let remoteImage: any View

        // MARK: - Item Info Actions

        let onSave: () -> Void
        let onClose: () -> Void

        // MARK: - Body

        var body: some View {
            NavigationView {
                VStack(alignment: .leading, spacing: 16) {
                    remoteImage
                        .eraseToAnyView()
                        .frame(width: 60, height: 180, alignment: .leading)

                    Text(itemInfo.name ?? L10n.unknown)
                        .foregroundStyle(Color.primary)
                        .font(.headline)

                    Text(itemInfo.premiereDate?.formatted(.dateTime.year().month().day()) ?? .emptyDash)
                        .foregroundStyle(Color.primary)
                        .font(.subheadline)

                    Text(itemInfo.overview ?? L10n.unknown)
                        .foregroundStyle(Color.secondary)

                    Spacer()

                    Text(itemInfo.searchProviderName ?? L10n.unknown)
                        .foregroundStyle(Color.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(L10n.useAsItem.localizedCapitalized)
                .navigationBarCloseButton {
                    onClose()
                }
                .topBarTrailing {
                    Button(L10n.save) {
                        onSave()
                    }
                    .buttonStyle(.toolbarPill)
                }
            }
        }
    }
}
