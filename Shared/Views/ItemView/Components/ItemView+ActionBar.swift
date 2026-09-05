//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct ActionBar: View {

        @FocusState
        private var focusedButton: String?

        @ObservedObject
        var provider: ItemContentGroupProvider

        private var buttonConfiguration = ItemActionButtons.Configuration()

        let alignment: HorizontalAlignment

        init(
            provider: ItemContentGroupProvider,
            alignment: HorizontalAlignment = .center
        ) {
            self.provider = provider
            self.alignment = alignment
        }

        var body: some View {
            let (visible, overflow, menu) = buttonConfiguration.resolvedButtons(for: provider)
            let defaultFocusedButton = provider.item.presentPlayButton ?
                ItemView.Component.play : visible.first?.id ?? ItemView.Component.menu

            VStack(alignment: alignment, spacing: UIDevice.isTV ? 24 : 8) {
                if provider.item.presentPlayButton {
                    PlayButton(provider: provider)
                        .coordinatedFocus(ItemView.Component.play, selection: $focusedButton)
                        .frame(height: UIDevice.isTV ? 75 : 44)
                }

                ItemActionButtons(
                    provider: provider,
                    buttons: visible,
                    overflowButtons: overflow,
                    menuButtons: menu,
                    focusedButton: $focusedButton
                )
            }
            .focusSection()
            .defaultFocus(
                $focusedButton,
                defaultFocusedButton,
                priority: .userInitiated
            )
            .multilineTextAlignment(.center)
        }
    }
}
