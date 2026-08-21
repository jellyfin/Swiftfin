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

        @FocusState
        private var focusedButton: String?

        @ObservedObject
        var provider: ItemContentGroupProvider

        @Router
        private var router

        @StoredValue(.User.enabledTrailers)
        private var enabledTrailers: TrailerSelection

        @Default(.Customization.itemBarActionButtons)
        private var barActionButtons: [ItemActionButton]
        @Default(.Customization.itemMenuActionButtons)
        private var menuActionButtons: [ItemActionButton]

        @StateObject
        private var deleteViewModel: ItemEditorViewModel

        let alignment: HorizontalAlignment

        private var resolvedButtons: (visible: [ItemActionButton], overflow: [ItemActionButton], menu: [ItemActionButton]) {
            ItemActionButtons.resolvedButtons(
                bar: barActionButtons,
                menu: menuActionButtons,
                for: provider,
                enabledTrailers: enabledTrailers
            )
        }

        private var defaultFocusedButton: String {
            guard !provider.item.presentPlayButton else {
                return ItemView.Component.play
            }

            return resolvedButtons.visible.first?.id ?? ItemView.Component.menu
        }

        init(
            provider: ItemContentGroupProvider,
            alignment: HorizontalAlignment = .center
        ) {
            self.provider = provider
            self.alignment = alignment
            self._deleteViewModel = StateObject(wrappedValue: ItemEditorViewModel(item: provider.item))
        }

        var body: some View {
            VStack(alignment: alignment, spacing: UIDevice.isTV ? 24 : 8) {
                if provider.item.presentPlayButton {
                    PlayButton(provider: provider)
                        .coordinatedFocus(ItemView.Component.play, selection: $focusedButton)
                        .frame(height: UIDevice.isTV ? 75 : 44)
                }

                ItemActionButtons(
                    provider: provider,
                    focusedButton: $focusedButton
                )
                .frame(height: UIDevice.isTV ? 75 : 44)
            }
            .focusSection()
            .defaultFocus(
                $focusedButton,
                defaultFocusedButton,
                priority: .userInitiated
            )
            .confirmationDialog(
                L10n.deleteItemConfirmationMessage,
                isPresented: $provider.isPresentingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    L10n.confirm,
                    role: .destructive,
                    action: deleteViewModel.delete
                )

                Button(L10n.cancel, role: .cancel) {}
            }
            .multilineTextAlignment(.center)
            .onNotification(.didDeleteItem) { _ in
                UIDevice.feedback(.success)
                router.dismiss()
            }
            .errorMessage($deleteViewModel.error)
            #if os(iOS)
                .navigationBarMenuButton(
                    isHidden: resolvedButtons.overflow.isEmpty && resolvedButtons.menu.isEmpty
                ) {
                    ItemActionButtons.MenuContent(
                        provider: provider,
                        buttons: resolvedButtons.overflow,
                        menuButtons: resolvedButtons.menu
                    )
                }
            #endif
        }
    }
}
