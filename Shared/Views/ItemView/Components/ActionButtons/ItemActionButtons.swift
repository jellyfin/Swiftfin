//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

private struct ItemActionButtonLabelStyle: LabelStyle {

    @Environment(\.isSelected)
    private var isSelected

    var activeColor: Color?

    private var iconSize: CGFloat {
        UIDevice.isTV ? 40 : 24
    }

    private var tint: Color {
        guard isSelected, let activeColor else {
            return .gray.opacity(0.15)
        }

        return activeColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.icon
            .font(UIDevice.isTV ? .system(size: 30) : .title3)
            .frame(width: iconSize, height: iconSize)
            .padding(UIDevice.isTV ? 16 : 8)
            .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
            .backport
            .glassEffect(
                .regular.selection(
                    tint: tint,
                    foregroundColor: .primary
                ),
                in: .capsule
            )
    }
}

struct ItemActionButtons: View {

    static let maximumButtons = 4

    static var buttonHeight: CGFloat {
        UIDevice.isTV ? 75 : 44
    }

    static var spacing: CGFloat {
        UIDevice.isTV ? 24 : 8
    }

    @ObservedObject
    var provider: ItemContentGroupProvider

    @StoredValue(.User.enabledTrailers)
    private var enabledTrailers: TrailerSelection

    @Default(.Customization.itemBarActionButtons)
    private var barActionButtons: [ItemActionButton]
    @Default(.Customization.itemMenuActionButtons)
    private var menuActionButtons: [ItemActionButton]

    let focusedButton: FocusState<String?>.Binding

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
        _ button: ItemActionButton,
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
            provider.item.presentPlayButton
        case .refresh:
            provider.item.canEditMetadata
        case .subtitles:
            provider.item.canEditSubtitles
        case .delete:
            provider.item.canDelete == true
        #if os(iOS)
        case .editMetadata:
            provider.item.canEditMetadata
        #endif
        }
    }

    private static func availableButtons(
        _ buttons: [ItemActionButton],
        for provider: ItemContentGroupProvider,
        enabledTrailers: TrailerSelection
    ) -> [ItemActionButton] {
        buttons.filter {
            isAvailable($0, for: provider, enabledTrailers: enabledTrailers)
        }
    }

    static func resolvedButtons(
        bar: [ItemActionButton],
        menu: [ItemActionButton],
        for provider: ItemContentGroupProvider,
        enabledTrailers: TrailerSelection
    ) -> (visible: [ItemActionButton], overflow: [ItemActionButton], menu: [ItemActionButton]) {
        let bar = availableButtons(bar, for: provider, enabledTrailers: enabledTrailers)
        let menu = availableButtons(menu, for: provider, enabledTrailers: enabledTrailers)

        let hasBarMenu = UIDevice.isTV && (menu.isNotEmpty || bar.count > maximumButtons)
        let visible = Array(bar.prefix(hasBarMenu ? maximumButtons - 1 : maximumButtons))

        return (
            visible: visible,
            overflow: Array(bar.dropFirst(visible.count)),
            menu: menu
        )
    }

    @ViewBuilder
    static func view(for button: ItemActionButton) -> some View {
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
        case .delete:
            Delete()
        #if os(iOS)
        case .editMetadata:
            Edit()
        #endif
        }
    }

    var body: some View {
        let (visible, overflow, menu) = Self.resolvedButtons(
            bar: barActionButtons,
            menu: menuActionButtons,
            for: provider,
            enabledTrailers: enabledTrailers
        )

        let hasBarMenu = UIDevice.isTV && (overflow.isNotEmpty || menu.isNotEmpty)

        if visible.isNotEmpty || hasBarMenu {
            HStack(alignment: .center, spacing: Self.spacing) {
                ForEach(visible) { button in
                    Self.view(for: button)
                        .labelStyle(ItemActionButtonLabelStyle(activeColor: button.activeColor))
                        .focused(focusedButton, equals: button.id)
                }

                if hasBarMenu {
                    Menu {
                        MenuContent(
                            provider: provider,
                            buttons: overflow,
                            menuButtons: menu
                        )
                    } label: {
                        Label(L10n.menu, systemImage: "ellipsis")
                    }
                    .menuStyle(.button)
                    .labelStyle(ItemActionButtonLabelStyle())
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(.primary, .secondary)
                    .focused(focusedButton, equals: ItemView.Component.menu)
                }
            }
            .environmentObject(provider)
            .frame(height: Self.buttonHeight)
            .backport
            .buttonBorderShape(.capsule)
            .buttonStyle(BasicHoverButtonStyle())
            .font(.title3)
            .fontWeight(.semibold)
        }
    }
}

extension ItemActionButtons {

    struct MenuContent: View {

        @ObservedObject
        var provider: ItemContentGroupProvider

        let buttons: [ItemActionButton]
        let menuButtons: [ItemActionButton]

        var body: some View {
            Group {
                ForEach(
                    buttons,
                    content: ItemActionButtons.view(for:)
                )

                if buttons.isNotEmpty, menuButtons.isNotEmpty {
                    Divider()
                }

                ForEach(
                    menuButtons,
                    content: ItemActionButtons.view(for:)
                )
            }
            .environmentObject(provider)
            .withViewContext(.isInMenu)
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(.primary)
        }
    }
}
