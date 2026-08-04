//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView.ActionButtons {

    struct MenuContent: View {

        @ObservedObject
        var provider: ItemContentGroupProvider

        let buttons: [ContentGroupActionButton]

        var body: some View {
            ForEach(
                buttons,
                content: ItemView.ActionButtons.view(for:)
            )
            .environmentObject(provider)
            .withViewContext(.isInMenu)
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(.primary)
        }
    }
}
