//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemActionButtons {

    struct Subtitles: View {

        @EnvironmentObject
        private var provider: ItemContentGroupProvider

        @Router
        private var router

        var body: some View {
            Button {
                #if os(iOS)
                router.route(to: .editSubtitles(item: provider.item))
                #else
                router.route(to: .searchSubtitle(viewModel: .init(item: provider.item)))
                #endif
            } label: {
                Label(
                    ItemActionButton.subtitles.displayTitle,
                    systemImage: ItemActionButton.subtitles.systemImage
                )
            }
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(.primary, .secondary)
        }
    }
}
