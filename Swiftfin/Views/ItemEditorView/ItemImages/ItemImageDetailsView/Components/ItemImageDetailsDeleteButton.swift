//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemImageDetailsView {

    struct DeleteButton: View {

        // MARK: - Delete Action

        let onDelete: () -> Void

        // MARK: - Dialog State

        @State
        private var isPresentingConfirmation: Bool = false

        // MARK: - Body

        var body: some View {
            ListRowButton(L10n.delete, role: .destructive) {
                isPresentingConfirmation = true
            }
            .confirmationDialog(
                L10n.delete,
                isPresented: $isPresentingConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    L10n.delete,
                    role: .destructive,
                    action: onDelete
                )

                Button(L10n.cancel, role: .cancel) {
                    isPresentingConfirmation = false
                }
            } message: {
                Text(L10n.deleteItemConfirmationMessage)
            }
        }
    }
}
