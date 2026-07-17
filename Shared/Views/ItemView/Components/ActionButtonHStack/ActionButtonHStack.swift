//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct ActionButtonHStack: View {

        @ObservedObject
        var provider: ItemContentGroupProvider

        @Router
        private var router

        @StoredValue(.User.enabledTrailers)
        private var enabledTrailers: TrailerSelection

        private var hasTrailers: Bool {
            if enabledTrailers.contains(.local), provider.localTrailers.isNotEmpty {
                return true
            }

            if enabledTrailers.contains(.external), provider.item.remoteTrailers?.isNotEmpty == true {
                return true
            }

            return false
        }

        @ViewBuilder
        private func materialLabel(
            _ title: String,
            systemImage: String,
            tint: Color,
            foregroundColor: Color,
            isRotated: Bool = false
        ) -> some View {
            #if os(tvOS)
            let shape: Rectangle = .rect
            #else
            let shape: RoundedRectangle = .rect(cornerRadius: 10, style: .circular)
            #endif

            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
                    .rotationEffect(isRotated ? .degrees(90) : .degrees(0))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .backport
            .glassEffect(
                .regular.selection(
                    tint: tint,
                    foregroundColor: foregroundColor
                ),
                in: shape
            )
        }

        var body: some View {
            HStack(alignment: .center, spacing: UIDevice.isTV ? 30 : 10) {

                // MARK: Played

                if provider.item.canBePlayed {
                    let isCheckmarkSelected = provider.item.userData?.isPlayed == true

                    Button {
                        Task { await provider.toggleIsPlayed() }
                    } label: {
                        materialLabel(
                            L10n.played,
                            systemImage: "checkmark",
                            tint: .jellyfinPurple,
                            foregroundColor: .primary
                        )
                    }
                    #if !os(tvOS)
                    .foregroundStyle(.primary, .secondary)
                    #endif
                    .isSelected(isCheckmarkSelected)
                }

                // MARK: Favorite

                let isHeartSelected = provider.item.userData?.isFavorite == true

                Button {
                    Task { await provider.toggleIsFavorite() }
                } label: {
                    materialLabel(
                        L10n.favorited,
                        systemImage: isHeartSelected ? "heart.fill" : "heart",
                        tint: .pink,
                        foregroundColor: .primary
                    )
                }
                #if !os(tvOS)
                .foregroundStyle(.primary, .secondary)
                #endif
                .isSelected(isHeartSelected)

                // MARK: Trailer

                if hasTrailers {
                    TrailerMenu(
                        localTrailers: provider.localTrailers,
                        externalTrailers: provider.item.remoteTrailers ?? []
                    ) {
                        materialLabel(
                            L10n.trailers,
                            systemImage: "movieclapper",
                            tint: .pink,
                            foregroundColor: .primary
                        )
                    }
                }

                #if os(tvOS)

                // MARK: Options

                if provider.item.canEdit {
                    Menu {
                        EditItemMenuContent(item: provider.item)
                    } label: {
                        materialLabel(
                            L10n.advanced,
                            systemImage: "ellipsis",
                            tint: .clear,
                            foregroundColor: .primary,
                            isRotated: true
                        )
                    }
                    .frame(width: 60)
                    .menuStyle(.button)
                    .foregroundStyle(.primary, .secondary)
                }
                #endif
            }
            .frame(height: UIDevice.isTV ? 100 : 44)
            .labelStyle(.iconOnly)
            .buttonStyle(BasicHoverButtonStyle())
            .font(.title3)
            .fontWeight(.semibold)
        }
    }
}
