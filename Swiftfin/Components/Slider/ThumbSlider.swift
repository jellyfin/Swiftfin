//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct ThumbSlider: View {

    @Default(.VideoPlayer.Overlay.sliderColor)
    private var sliderColor

    @Binding
    private var isEditing: Bool
    @Binding
    private var progress: CGFloat

    private var trackMask: () -> any View
    private var topContent: () -> any View
    private var bottomContent: () -> any View
    private var leadingContent: () -> any View
    private var trailingContent: () -> any View

    var body: some View {
        Slider(progress: $progress)
            .gestureBehavior(.thumb)
            .onEditingChanged { isEditing in
                self.isEditing = isEditing
            }
            .track {
                Capsule()
                    .foregroundColor(sliderColor)
                    .frame(height: 5)
            }
            .trackBackground {
                Capsule()
                    .foregroundColor(Color.gray)
                    .opacity(0.5)
                    .frame(height: 5)
            }
            .thumb {
                ZStack {
                    Color.clear
                        .frame(height: 25)

                    Circle()
                        .foregroundColor(sliderColor)
                        .frame(width: isEditing ? 25 : 20)
                }
                .overlay {
                    Color.clear
                        .frame(width: 50, height: 50)
                        .contentShape(Rectangle())
                }
            }
            .trackMask(trackMask)
            .topContent(topContent)
            .bottomContent(bottomContent)
            .leadingContent(leadingContent)
            .trailingContent(trailingContent)
    }
}

extension ThumbSlider {

    init(progress: Binding<CGFloat>) {
        self.init(
            isEditing: .constant(false),
            progress: progress,
            trackMask: { Color.white },
            topContent: { EmptyView() },
            bottomContent: { EmptyView() },
            leadingContent: { EmptyView() },
            trailingContent: { EmptyView() }
        )
    }

    func isEditing(_ isEditing: Binding<Bool>) -> Self {
        copy(modifying: \._isEditing, with: isEditing)
    }

    func trackMask(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.trackMask, with: content)
    }

    func topContent(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.topContent, with: content)
    }

    func bottomContent(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.bottomContent, with: content)
    }

    func leadingContent(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.leadingContent, with: content)
    }

    func trailingContent(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.trailingContent, with: content)
    }
}
