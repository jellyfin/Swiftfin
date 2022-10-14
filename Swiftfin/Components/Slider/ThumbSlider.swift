//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ThumbSlider<TopContent: View, BottomContent: View, LeadingContent: View, TrailingContent: View>: View {

    @Binding
    private var progress: CGFloat
    @Binding
    private var rate: CGFloat
    @State
    private var isEditing: Bool = false
    private var topContent: () -> TopContent
    private var bottomContent: () -> BottomContent
    private var leadingContent: () -> LeadingContent
    private var trailingContent: () -> TrailingContent
    private var onEditingChanged: (Bool) -> Void

    var body: some View {
        Slider(progress: $progress)
            .gestureBehavior(.thumb)
            .rate { pointOffset in
                if abs(pointOffset.y) > 50 {
                    return 0.01
                } else {
                    return 1
                }
            }
            .onEditingChanged { isEditing in
                self.isEditing = isEditing
                onEditingChanged(isEditing)
            }
            .track { _, _ in
                Capsule()
                    .foregroundColor(Color.purple)
                    .frame(height: 5)
            }
            .trackBackground { _, _ in
                Capsule()
                    .foregroundColor(Color.gray)
                    .opacity(0.5)
                    .frame(height: 5)
            }
            .trackMask {
//                Color.white
                ItemVideoPlayer.Overlay.ChapterTrack()
            }
            .thumb { isEditing, _ in
                ZStack {
                    Color.clear
                        .frame(height: 25)

                    Circle()
                        .foregroundColor(Color.purple)
                        .frame(width: isEditing ? 25 : 20)
                }
                .overlay {
                    Color.clear
                        .frame(width: 50, height: 50)
                        .contentShape(Rectangle())
                }
            }
            .topContent(topContent)
            .bottomContent(bottomContent)
            .leadingContent(leadingContent)
            .trailingContent(trailingContent)
    }
}

extension ThumbSlider where TopContent == EmptyView,
    BottomContent == EmptyView,
    LeadingContent == EmptyView,
    TrailingContent == EmptyView
{

    init(progress: Binding<CGFloat>) {
        self.init(
            progress: progress,
            rate: .constant(1),
            topContent: { EmptyView() },
            bottomContent: { EmptyView() },
            leadingContent: { EmptyView() },
            trailingContent: { EmptyView() },
            onEditingChanged: { _ in }
        )
    }
}

extension ThumbSlider {

    func topContent<C: View>(@ViewBuilder _ content: @escaping () -> C)
    -> ThumbSlider<C, BottomContent, LeadingContent, TrailingContent> {
        .init(
            progress: $progress,
            rate: $rate,
            topContent: content,
            bottomContent: bottomContent,
            leadingContent: leadingContent,
            trailingContent: trailingContent,
            onEditingChanged: onEditingChanged
        )
    }

    func bottomContent<C: View>(@ViewBuilder _ content: @escaping () -> C)
    -> ThumbSlider<TopContent, C, LeadingContent, TrailingContent> {
        .init(
            progress: $progress,
            rate: $rate,
            topContent: topContent,
            bottomContent: content,
            leadingContent: leadingContent,
            trailingContent: trailingContent,
            onEditingChanged: onEditingChanged
        )
    }

    func leadingContent<C: View>(@ViewBuilder _ content: @escaping () -> C)
    -> ThumbSlider<TopContent, BottomContent, C, TrailingContent> {
        .init(
            progress: $progress,
            rate: $rate,
            topContent: topContent,
            bottomContent: bottomContent,
            leadingContent: content,
            trailingContent: trailingContent,
            onEditingChanged: onEditingChanged
        )
    }

    func trailingContent<C: View>(@ViewBuilder _ content: @escaping () -> C)
    -> ThumbSlider<TopContent, BottomContent, LeadingContent, C> {
        .init(
            progress: $progress,
            rate: $rate,
            topContent: topContent,
            bottomContent: bottomContent,
            leadingContent: leadingContent,
            trailingContent: content,
            onEditingChanged: onEditingChanged
        )
    }

    func onEditingChanged(_ action: @escaping (Bool) -> Void) -> Self {
        copy(modifying: \.onEditingChanged, with: action)
    }

    func rate(_ rate: Binding<CGFloat>) -> Self {
        copy(modifying: \._rate, with: rate)
    }
}
