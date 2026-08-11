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

    let focusedButton: FocusState<String?>.Binding

    @StoredValue(.User.enabledTrailers)
    private var enabledTrailers: TrailerSelection

    @Default(.Customization.itemBarActionButtons)
    private var barActionButtons: [ItemActionButton]
    @Default(.Customization.itemMenuActionButtons)
    private var menuActionButtons: [ItemActionButton]

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
            provider.item.presentPlayButton && provider.mediaPlayerItemProvider?.hasPlaybackOptions == true
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

    static func availableButtons(
        _ buttons: [ItemActionButton],
        for provider: ItemContentGroupProvider,
        enabledTrailers: TrailerSelection
    ) -> [ItemActionButton] {
        buttons.filter {
            isAvailable($0, for: provider, enabledTrailers: enabledTrailers)
        }
    }

    private var availableBarButtons: [ItemActionButton] {
        Self.availableButtons(barActionButtons, for: provider, enabledTrailers: enabledTrailers)
    }

    private var availableMenuButtons: [ItemActionButton] {
        Self.availableButtons(menuActionButtons, for: provider, enabledTrailers: enabledTrailers)
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
        let bar = availableBarButtons
        let menu = availableMenuButtons
        let hasOverflowMenu = menu.isNotEmpty || bar.count > Self.maximumButtons
        let visible = Array(bar.prefix(hasOverflowMenu ? Self.maximumButtons - 1 : Self.maximumButtons))
        let overflow = Array(bar.dropFirst(visible.count))

        if bar.isNotEmpty || menu.isNotEmpty {
            HStack(alignment: .center, spacing: Self.spacing) {
                ForEach(visible) { button in
                    Self.view(for: button)
                        .labelStyle(ItemActionButtonLabelStyle(activeColor: button.activeColor))
                        .focused(focusedButton, equals: button.id)
                }

                if hasOverflowMenu {
                    Menu {
                        Group {
                            ForEach(
                                overflow,
                                content: Self.view(for:)
                            )

                            if overflow.isNotEmpty, menu.isNotEmpty {
                                Divider()
                            }

                            ForEach(
                                menu,
                                content: Self.view(for:)
                            )
                        }
                        .withViewContext(.isInMenu)
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(.primary)
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
