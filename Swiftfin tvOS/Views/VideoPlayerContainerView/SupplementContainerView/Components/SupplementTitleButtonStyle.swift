//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.UIVideoPlayerContainerViewController.SupplementContainerView {

    struct SupplementTitleButtonStyle: ButtonStyle {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isFocused)
        private var isFocused
        @Environment(\.isSelected)
        private var isSelected

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .fontWeight(.semibold)
                .foregroundStyle(isFocused || isSelected ? .black : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    if isFocused || isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(.white)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isFocused ? accentColor : .white, lineWidth: 4)
                }
                .if(isFocused) { button in
                    button
                        .posterShadow()
                }
                .scaleEffect(isFocused ? 1.2 : 1)
                .animation(.bouncy(duration: 0.4), value: isFocused)
        }
    }
}
