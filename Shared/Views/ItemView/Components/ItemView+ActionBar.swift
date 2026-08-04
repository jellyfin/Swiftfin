//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension ItemView {

    struct ActionBar: View {

        static var buttonHeight: CGFloat {
            UIDevice.isTV ? 75 : 44
        }

        static var spacing: CGFloat {
            UIDevice.isTV ? 24 : 8
        }

        @FocusState
        private var focusedButton: String?

        @ObservedObject
        var provider: ItemContentGroupProvider

        @StoredValue(.User.enabledTrailers)
        private var enabledTrailers: TrailerSelection

        @Default(.Customization.itemBarActionButtons)
        private var barActionButtons: [ContentGroupActionButton]

        let alignment: HorizontalAlignment

        private var defaultFocusedButton: String? {
            guard !provider.item.presentPlayButton else {
                return ItemView.Component.play
            }

            return ActionButtons.availableButtons(
                barActionButtons,
                for: provider,
                enabledTrailers: enabledTrailers
            )
            .first?.id
        }

        init(
            provider: ItemContentGroupProvider,
            alignment: HorizontalAlignment = .center
        ) {
            self.provider = provider
            self.alignment = alignment
        }

        var body: some View {
            VStack(alignment: alignment, spacing: Self.spacing) {
                if provider.item.presentPlayButton {
                    PlayButton(provider: provider)
                        .coordinatedFocus(ItemView.Component.play, selection: $focusedButton)
                }

                ActionButtons(
                    provider: provider,
                    focusedButton: $focusedButton
                )
            }
            .focusSection()
            .backport
            .defaultFocus(
                $focusedButton,
                defaultFocusedButton,
                priority: focusedButton == nil ? .userInitiated : .automatic
            )
        }
    }
}
