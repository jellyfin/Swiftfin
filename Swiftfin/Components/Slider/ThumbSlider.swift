//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct ThumbSlider<TrackMask: View, TopContent: View, BottomContent: View, LeadingContent: View, TrailingContent: View>: View {

    @Default(.VideoPlayer.Overlay.sliderColor)
    private var sliderColor

    @Binding
    private var isEditing: Bool
    @Binding
    private var progress: CGFloat
    @Binding
    private var rate: CGFloat

    private var trackMask: () -> TrackMask
    private var topContent: () -> TopContent
    private var bottomContent: () -> BottomContent
    private var leadingContent: () -> LeadingContent
    private var trailingContent: () -> TrailingContent

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

extension ThumbSlider where TrackMask == Color,
    TopContent == EmptyView,
    BottomContent == EmptyView,
    LeadingContent == EmptyView,
    TrailingContent == EmptyView
{

    init(progress: Binding<CGFloat>) {
        self.init(
            isEditing: .constant(false),
            progress: progress,
            rate: .constant(1),
            trackMask: { Color.white },
            topContent: { EmptyView() },
            bottomContent: { EmptyView() },
            leadingContent: { EmptyView() },
            trailingContent: { EmptyView() }
        )
    }
}

extension ThumbSlider {

    func isEditing(_ isEditing: Binding<Bool>) -> Self {
        copy(modifying: \._isEditing, with: isEditing)
    }

    func rate(_ rate: Binding<CGFloat>) -> Self {
        copy(modifying: \._rate, with: rate)
    }

    func trackMask<C: View>(@ViewBuilder _ content: @escaping () -> C)
    -> ThumbSlider<C, TopContent, BottomContent, LeadingContent, TrailingContent> {
        .init(
            isEditing: $isEditing,
            progress: $progress,
            rate: $rate,
            trackMask: content,
            topContent: topContent,
            bottomContent: bottomContent,
            leadingContent: leadingContent,
            trailingContent: trailingContent
        )
    }

    func topContent<C: View>(@ViewBuilder _ content: @escaping () -> C)
    -> ThumbSlider<TrackMask, C, BottomContent, LeadingContent, TrailingContent> {
        .init(
            isEditing: $isEditing,
            progress: $progress,
            rate: $rate,
            trackMask: trackMask,
            topContent: content,
            bottomContent: bottomContent,
            leadingContent: leadingContent,
            trailingContent: trailingContent
        )
    }

    func bottomContent<C: View>(@ViewBuilder _ content: @escaping () -> C)
    -> ThumbSlider<TrackMask, TopContent, C, LeadingContent, TrailingContent> {
        .init(
            isEditing: $isEditing,
            progress: $progress,
            rate: $rate,
            trackMask: trackMask,
            topContent: topContent,
            bottomContent: content,
            leadingContent: leadingContent,
            trailingContent: trailingContent
        )
    }

    func leadingContent<C: View>(@ViewBuilder _ content: @escaping () -> C)
    -> ThumbSlider<TrackMask, TopContent, BottomContent, C, TrailingContent> {
        .init(
            isEditing: $isEditing,
            progress: $progress,
            rate: $rate,
            trackMask: trackMask,
            topContent: topContent,
            bottomContent: bottomContent,
            leadingContent: content,
            trailingContent: trailingContent
        )
    }

    func trailingContent<C: View>(@ViewBuilder _ content: @escaping () -> C)
    -> ThumbSlider<TrackMask, TopContent, BottomContent, LeadingContent, C> {
        .init(
            isEditing: $isEditing,
            progress: $progress,
            rate: $rate,
            trackMask: trackMask,
            topContent: topContent,
            bottomContent: bottomContent,
            leadingContent: leadingContent,
            trailingContent: content
        )
    }
}
