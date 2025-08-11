//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct NavigationBarMenuButtonModifier<Content: View>: ViewModifier {

    @Default(.accentColor)
    private var accentColor

    let isLoading: Bool
    let isHidden: Bool
    let items: () -> Content

    func body(content: Self.Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {

                if isLoading {
                    ProgressView()
                }

                if !isHidden {
                    Menu {
                        items()
                    } label: {
                        Label(L10n.options, systemImage: "ellipsis")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 10, height: 10)
                            .padding(10)
                    }
                    .labelStyle(.iconOnly)
                    .menuStyle(.button)
                    .buttonStyle(.tintedMaterial(tint: Color.gray.opacity(0.3), foregroundColor: accentColor))
                    .clipShape(.circle)
                    .isSelected(true)
                }
            }
        }
    }
}
