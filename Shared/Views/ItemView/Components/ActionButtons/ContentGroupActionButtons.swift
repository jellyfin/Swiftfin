//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct ContentGroupActionButtons: View {

    static let maximumButtons = 4

    static var buttonHeight: CGFloat {
        UIDevice.isTV ? 75 : 44
    }

    static var spacing: CGFloat {
        UIDevice.isTV ? 24 : 8
    }

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
        Self.spacing
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

    static func toolbarButtons(
        bar: [ContentGroupActionButton],
        for provider: ItemContentGroupProvider,
        enabledTrailers: TrailerSelection
    ) -> [ContentGroupActionButton] {
        guard !UIDevice.isTV else { return [] }

        return Array(
            availableButtons(bar, for: provider, enabledTrailers: enabledTrailers)
                .dropFirst(maximumButtons)
        )
    }

    private var availableBarButtons: [ContentGroupActionButton] {
        Self.availableButtons(barActionButtons, for: provider, enabledTrailers: enabledTrailers)
    }

    private var availableMenuButtons: [ContentGroupActionButton] {
        Self.availableButtons(menuActionButtons, for: provider, enabledTrailers: enabledTrailers)
    }

    private var maximumVisibleButtons: Int {
        guard UIDevice.isTV, containerWidth > 0 else { return Self.maximumButtons }

        let fittingButtons = Int((containerWidth + spacing) / (minimumButtonWidth + spacing))

        return max(1, min(Self.maximumButtons, fittingButtons))
    }

    private func visibleButtons(
        bar: [ContentGroupActionButton],
        menu: [ContentGroupActionButton]
    ) -> [ContentGroupActionButton] {
        guard UIDevice.isTV, menu.isNotEmpty || bar.count > maximumVisibleButtons else {
            return Array(bar.prefix(maximumVisibleButtons))
        }

        return Array(bar.prefix(max(0, maximumVisibleButtons - 1)))
    }

    private func overflowButtons(
        bar: [ContentGroupActionButton],
        menu: [ContentGroupActionButton]
    ) -> [ContentGroupActionButton] {
        guard UIDevice.isTV else { return [] }
        return Array(bar.dropFirst(visibleButtons(bar: bar, menu: menu).count))
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

    private var menuLabel: ContentGroupActionButtonLabel {
        ContentGroupActionButtonLabel(
            title: L10n.menu,
            systemImage: "ellipsis"
        )
    }

    @ViewBuilder
    private func overflowMenu(
        buttons: [ContentGroupActionButton],
        menuButtons: [ContentGroupActionButton]
    ) -> some View {
        Menu {
            MenuContent(
                provider: provider,
                buttons: buttons,
                menuButtons: menuButtons
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
        let menu = UIDevice.isTV ? availableMenuButtons : []

        if bar.isNotEmpty || menu.isNotEmpty {
            let visible = visibleButtons(bar: bar, menu: menu)
            let overflow = overflowButtons(bar: bar, menu: menu)

            HStack(alignment: .center, spacing: spacing) {
                ForEach(visible) { button in
                    Self.view(for: button)
                        .focused(focusedButton, equals: button.id)
                }

                if overflow.isNotEmpty || menu.isNotEmpty {
                    overflowMenu(buttons: overflow, menuButtons: menu)
                        .focused(focusedButton, equals: ItemView.Component.menu)
                }
            }
            .environmentObject(provider)
            .frame(height: ContentGroupActionButtons.buttonHeight)
            .backport
            .buttonBorderShape(.capsule)
            .buttonStyle(BasicHoverButtonStyle())
            .font(.title3)
            .fontWeight(.semibold)
            .if(UIDevice.isTV) { view in
                view.onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.width
                } action: { newValue in
                    containerWidth = newValue
                }
            }
        }
    }
}
