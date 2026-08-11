//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemActionButtons {

    struct Delete: View {

        @EnvironmentObject
        private var provider: ItemContentGroupProvider

        var body: some View {
            Button(role: .destructive) {
                provider.isPresentingDeleteConfirmation = true
            } label: {
                ItemActionButtonLabel(.delete)
            }
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(.primary, .secondary)
        }
    }
}
