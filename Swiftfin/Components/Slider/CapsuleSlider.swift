//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct CapsuleSlider<TrackMask: View, TopContent: View, BottomContent: View, LeadingContent: View, TrailingContent: View>: View {

    @Default(.VideoPlayer.Overlay.sliderColor)
    private var sliderColor

    @Binding
    private var progress: CGFloat
    @Binding
    private var rate: CGFloat

    @State
    private var isEditing: Bool = false

    private var trackMask: () -> TrackMask
    private var topContent: () -> TopContent
    private var bottomContent: () -> BottomContent
    private var leadingContent: () -> LeadingContent
    private var trailingContent: () -> TrailingContent
    private var onEditingChanged: (Bool) -> Void

    var body: some View {
        Slider(progress: $progress)
            .gestureBehavior(.track)
            .trackGesturePadding(.init(top: 10, leading: 0, bottom: 30, trailing: 0))
            .rate { pointOffset in
                if abs(pointOffset.y) > 50 {
                    rate = 0.01
                    return 0.01
                } else {
                    rate = 1
                    return 1
                }
            }
            .onEditingChanged { isEditing in
                self.isEditing = isEditing
                onEditingChanged(isEditing)
            }
            .track { isEditing, _ in
                Capsule()
                    .frame(height: isEditing ? 20 : 10)
                    .foregroundColor(isEditing ? sliderColor : sliderColor.opacity(0.8))
            }
            .trackBackground { isEditing, _ in
                Capsule()
                    .frame(height: isEditing ? 20 : 10)
                    .foregroundColor(Color.gray)
                    .opacity(0.5)
            }
            .trackMask(trackMask)
            .topContent(topContent)
            .bottomContent(bottomContent)
            .leadingContent(leadingContent)
            .trailingContent(trailingContent)
    }
}

extension CapsuleSlider where TrackMask == Color,
    TopContent == EmptyView,
    BottomContent == EmptyView,
    LeadingContent == EmptyView,
    TrailingContent == EmptyView
{

    init(progress: Binding<CGFloat>) {
        self.init(
            progress: progress,
            rate: .constant(1),
            trackMask: { Color.white },
            topContent: { EmptyView() },
            bottomContent: { EmptyView() },
            leadingContent: { EmptyView() },
            trailingContent: { EmptyView() },
            onEditingChanged: { _ in }
        )
    }
}

extension CapsuleSlider {

    func trackMask<C: View>(@ViewBuilder _ content: @escaping () -> C)
    -> CapsuleSlider<C, TopContent, BottomContent, LeadingContent, TrailingContent> {
        .init(
            progress: $progress,
            rate: $rate,
            trackMask: content,
            topContent: topContent,
            bottomContent: bottomContent,
            leadingContent: leadingContent,
            trailingContent: trailingContent,
            onEditingChanged: onEditingChanged
        )
    }

    func topContent<C: View>(@ViewBuilder _ content: @escaping () -> C)
    -> CapsuleSlider<TrackMask, C, BottomContent, LeadingContent, TrailingContent> {
        .init(
            progress: $progress,
            rate: $rate,
            trackMask: trackMask,
            topContent: content,
            bottomContent: bottomContent,
            leadingContent: leadingContent,
            trailingContent: trailingContent,
            onEditingChanged: onEditingChanged
        )
    }

    func bottomContent<C: View>(@ViewBuilder _ content: @escaping () -> C)
    -> CapsuleSlider<TrackMask, TopContent, C, LeadingContent, TrailingContent> {
        .init(
            progress: $progress,
            rate: $rate,
            trackMask: trackMask,
            topContent: topContent,
            bottomContent: content,
            leadingContent: leadingContent,
            trailingContent: trailingContent,
            onEditingChanged: onEditingChanged
        )
    }

    func leadingContent<C: View>(@ViewBuilder _ content: @escaping () -> C)
    -> CapsuleSlider<TrackMask, TopContent, BottomContent, C, TrailingContent> {
        .init(
            progress: $progress,
            rate: $rate,
            trackMask: trackMask,
            topContent: topContent,
            bottomContent: bottomContent,
            leadingContent: content,
            trailingContent: trailingContent,
            onEditingChanged: onEditingChanged
        )
    }

    func trailingContent<C: View>(@ViewBuilder _ content: @escaping () -> C)
    -> CapsuleSlider<TrackMask, TopContent, BottomContent, LeadingContent, C> {
        .init(
            progress: $progress,
            rate: $rate,
            trackMask: trackMask,
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
