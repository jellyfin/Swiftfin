//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension APIKeysView {

    struct APIKeysRow: View {

        @State
        private var showCopiedAlert = false
        @State
        private var showDeleteConfirmation = false
        @State
        private var showReplaceConfirmation = false

        let apiKey: AuthenticationInfo
        let deleteAction: () -> Void
        let replaceAction: () -> Void

        @ViewBuilder
        private var rowContent: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(apiKey.appName ?? L10n.unknown)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                Text(apiKey.accessToken ?? L10n.unknown)
                    .lineLimit(2)

                LabeledContent(L10n.dateCreated) {
                    if let creationDate = apiKey.dateCreated {
                        Text(creationDate, format: .dateTime)
                    } else {
                        Text(L10n.unknown)
                    }
                }
                .monospacedDigit()
            }
            .font(.subheadline)
            .multilineTextAlignment(.leading)
        }

        var body: some View {
            Button {
                UIPasteboard.general.string = apiKey.accessToken
                showCopiedAlert = true
            } label: {
                rowContent
            }
            .foregroundStyle(.primary, .secondary)
            .alert(
                L10n.apiKeyCopied,
                isPresented: $showCopiedAlert
            ) {
                Button(L10n.ok, role: .cancel) {}
            } message: {
                Text(L10n.apiKeyCopiedMessage)
            }
            .confirmationDialog(
                L10n.delete,
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    L10n.delete,
                    role: .destructive,
                    action: deleteAction
                )
                Button(
                    L10n.cancel,
                    role: .cancel
                ) {}
            } message: {
                Text(L10n.deleteItemConfirmation)
            }
            .confirmationDialog(
                L10n.replace,
                isPresented: $showReplaceConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    L10n.replace,
                    role: .destructive,
                    action: replaceAction
                )
                Button(
                    L10n.cancel,
                    role: .cancel
                ) {}
            } message: {
                Text(L10n.replaceItemConfirmation)
            }
            .swipeActions {

                Button(
                    L10n.delete,
                    systemImage: "trash"
                ) {
                    showDeleteConfirmation = true
                }
                .tint(.red)

                Button(
                    L10n.replace,
                    systemImage: "arrow.clockwise"
                ) {
                    showReplaceConfirmation = true
                }
                .tint(.blue)
            }
        }
    }
}
