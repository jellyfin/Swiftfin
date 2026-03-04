//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: both axes

struct ScrollIfLargerThanContainerModifier: ViewModifier {

    let padding: CGFloat
    let fadeOut: Bool
    let focusBinding: FocusState<Bool>.Binding?

    func body(content: Content) -> some View {
        ViewThatFits(in: .vertical) {
            // if content is small
            content

            // if content too tall
            ScrollView {
                content
            }
            .optionallyFocused(focusBinding)
            .mask {
                if fadeOut {
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0.0),
                            .init(color: .black, location: 0.88),
                            .init(color: .clear, location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                } else {
                    Color.black
                }
            }
            .backport // iOS 17
            .scrollClipDisabled()
            .scrollIndicators(.never)
        }
    }
}

extension View {

    @ViewBuilder
    func optionallyFocused(_ binding: FocusState<Bool>.Binding?) -> some View {
        if let binding {
            focused(binding)
        } else {
            self
        }
    }
}
