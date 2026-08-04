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

    struct ActionButtons: View {

        @ObservedObject
        var provider: ItemContentGroupProvider

        let focusedButton: FocusState<String?>.Binding

        @StoredValue(.User.enabledTrailers)
        private var enabledTrailers: TrailerSelection

        @Default(.Customization.itemBarActionButtons)
        private var barActionButtons: [ContentGroupActionButton]
        @Default(.Customization.itemMenuActionButtons)
        private var menuActionButtons: [ContentGroupActionButton]

        @State
        private var containerWidth: CGFloat = 0

        private var spacing: CGFloat {
            ItemView.ActionBar.spacing
        }

        private var minimumButtonWidth: CGFloat {
            UIDevice.isTV ? 90 : 60
        }

        private static func hasTrailers(
            for provider: ItemContentGroupProvider,
            enabledTrailers: TrailerSelection
        ) -> Bool {
            if enabledTrailers.contains(.local), provider.localTrailers.isNotEmpty {
                return true
            }

            if enabledTrailers.contains(.external), provider.item.remoteTrailers?.isNotEmpty == true {
                return true
            }

            return false
        }

        private static func isAvailable(
            _ button: ContentGroupActionButton,
            for provider: ItemContentGroupProvider,
            enabledTrailers: TrailerSelection
        ) -> Bool {
            switch button {
            case .played:
                provider.item.canBePlayed
            case .favorited:
                provider.item.canBeFavorited
            case .trailers:
                hasTrailers(for: provider, enabledTrailers: enabledTrailers)
            case .playback:
                provider.item.presentPlayButton && Playback.hasOptions(for: provider)
            case .refresh:
                provider.item.canEditMetadata
            case .subtitles:
                provider.item.canEditSubtitles
            #if os(tvOS)
            case .delete:
                provider.item.canDeleteItem
            #else
            case .editMetadata:
                provider.item.canEditMetadata
            #endif
            }
        }

        static func availableButtons(
            _ buttons: [ContentGroupActionButton],
            for provider: ItemContentGroupProvider,
            enabledTrailers: TrailerSelection
        ) -> [ContentGroupActionButton] {
            buttons.filter {
                isAvailable($0, for: provider, enabledTrailers: enabledTrailers)
            }
        }

        private var availableBarButtons: [ContentGroupActionButton] {
            Self.availableButtons(barActionButtons, for: provider, enabledTrailers: enabledTrailers)
        }

        private var availableMenuButtons: [ContentGroupActionButton] {
            Self.availableButtons(menuActionButtons, for: provider, enabledTrailers: enabledTrailers)
        }

        private func maximumVisibleButtons(from buttons: [ContentGroupActionButton]) -> Int {
            guard containerWidth > 0 else { return buttons.count }

            let fittingButtons = Int((containerWidth + spacing) / (minimumButtonWidth + spacing))

            return max(1, fittingButtons)
        }

        private func visibleButtons(
            bar: [ContentGroupActionButton],
            menu: [ContentGroupActionButton]
        ) -> [ContentGroupActionButton] {
            let maximum = maximumVisibleButtons(from: bar)

            guard menu.isNotEmpty || bar.count > maximum else {
                return Array(bar.prefix(maximum))
            }

            return Array(bar.prefix(max(0, maximum - 1)))
        }

        private func overflowButtons(
            bar: [ContentGroupActionButton],
            menu: [ContentGroupActionButton]
        ) -> [ContentGroupActionButton] {
            Array(bar.dropFirst(visibleButtons(bar: bar, menu: menu).count)) + menu
        }

        @ViewBuilder
        static func view(for button: ContentGroupActionButton) -> some View {
            switch button {
            case .played:
                Played()
            case .favorited:
                Favorited()
            case .trailers:
                Trailers()
            case .playback:
                Playback()
            case .refresh:
                Refresh()
            case .subtitles:
                Subtitles()
            #if os(tvOS)
            case .delete:
                Delete()
            #else
            case .editMetadata:
                Edit()
            #endif
            }
        }

        private var menuLabel: ActionButtonLabel {
            ActionButtonLabel(
                title: L10n.menu,
                systemImage: "ellipsis"
            )
        }

        @ViewBuilder
        private func overflowMenu(buttons: [ContentGroupActionButton]) -> some View {
            Menu {
                MenuContent(
                    provider: provider,
                    buttons: buttons
                )
            } label: {
                menuLabel
            }
            .menuStyle(.button)
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(.primary, .secondary)
        }

        var body: some View {
            let bar = availableBarButtons
            let menu = availableMenuButtons

            if bar.isNotEmpty || menu.isNotEmpty {
                let visible = visibleButtons(bar: bar, menu: menu)
                let overflow = overflowButtons(bar: bar, menu: menu)

                HStack(alignment: .center, spacing: spacing) {
                    ForEach(visible) { button in
                        Self.view(for: button)
                            .focused(focusedButton, equals: button.id)
                    }

                    if overflow.isNotEmpty {
                        overflowMenu(buttons: overflow)
                            .focused(focusedButton, equals: ItemView.Component.menu)
                    }
                }
                .environmentObject(provider)
                .frame(height: ItemView.ActionBar.buttonHeight)
                .backport
                .buttonBorderShape(.capsule)
                .buttonStyle(BasicHoverButtonStyle())
                .font(.title3)
                .fontWeight(.semibold)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.width
                } action: { newValue in
                    containerWidth = newValue
                }
            }
        }
    }
}
