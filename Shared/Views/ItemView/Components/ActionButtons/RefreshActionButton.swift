//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView.ActionButtons {

    struct Refresh: View {

        @EnvironmentObject
        private var provider: ItemContentGroupProvider

        @Router
        private var router

        var body: some View {
            Button {
                router.route(to: .itemMetadataRefresh(viewModel: .init(item: provider.item)))
            } label: {
                ItemView.ActionButtonLabel(.refresh)
            }
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(.primary, .secondary)
        }
    }
}
