//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.UIVideoPlayerContainerViewController.SupplementContainerView {

    struct SupplementTitleButtonStyle: ButtonStyle {

        @Environment(\.isFocused)
        private var isFocused
        @Environment(\.isSelected)
        private var isSelected

        private var scale: CGFloat {
            if isFocused {
                return 1.25
            } else {
                return 1
            }
        }

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .fontWeight(.semibold)
                .foregroundStyle(isFocused ? .black : isSelected ? .black : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    if isFocused || isSelected {
                        Rectangle()
                            .foregroundStyle(.white)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isFocused ? .black : .white, lineWidth: 8)
                }
                .mask {
                    RoundedRectangle(cornerRadius: 10)
                }
                .scaleEffect(scale)
                .animation(.bouncy(duration: 0.4), value: isFocused)
                .animation(.bouncy(duration: 0.4), value: isSelected)
        }
    }
}
