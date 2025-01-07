//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ItemImageDetailsView {

    struct DeleteButton: View {

        // MARK: - Defaults

        @Default(.accentColor)
        private var accentColor

        // MARK: - Delete Action

        let onDelete: () -> Void

        // MARK: - Header

        @ViewBuilder
        var body: some View {
            ListRowButton(L10n.delete) {
                onDelete()
            }
            .foregroundStyle(
                accentColor.overlayColor,
                .red
            )
        }
    }
}
