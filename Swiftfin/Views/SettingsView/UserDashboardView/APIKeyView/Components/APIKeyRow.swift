//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

extension APIKeyView {

    struct APIKeyRow: View {

        @ObservedObject
        private var box: BindingBox<AuthenticationInfo?>

        // MARK: - Actions

        private let onSelect: () -> Void
        private let onDelete: () -> Void

        private var apiKey: AuthenticationInfo {
            box.value ?? .init()
        }

        init(box: BindingBox<AuthenticationInfo?>, onSelect: @escaping () -> Void, onDelete: @escaping () -> Void) {
            self.box = box
            self.onSelect = onSelect
            self.onDelete = onDelete
        }

        // MARK: - Row Content

        @ViewBuilder
        private var rowContent: some View {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(apiKey.appName ?? L10n.unknown)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(apiKey.accessToken ?? L10n.unknown)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)

                    TextPairView(
                        L10n.dateCreated,
                        value: {
                            if let creationDate = apiKey.dateCreated {
                                Text(creationDate, format: .dateTime)
                            } else {
                                Text(L10n.unknown)
                            }
                        }()
                    )
                    .monospacedDigit()
                }
                .foregroundStyle(.primary, .secondary)

                Spacer()
            }
        }

        // MARK: - Body

        var body: some View {
            ListRow(insets: .init(vertical: 8, horizontal: 8)) {} content: {
                rowContent
            }
            .isSeparatorVisible(false)
            .onSelect(perform: onSelect)
            .swipeActions {
                Button(
                    L10n.delete,
                    systemImage: "trash",
                    action: onDelete
                )
                .tint(.red)
            }
        }
    }
}
