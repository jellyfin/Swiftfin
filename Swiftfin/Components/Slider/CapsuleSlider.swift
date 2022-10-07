//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CapsuleSlider<TopContent: View, BottomContent: View, LeadingContent: View, TrailingContent: View>: View {

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
            .gestureBehavior(.track)
            .trackGesturePadding(50)
//            .rate { _ in
//                rate
//            }
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
                    .foregroundColor(isEditing ? .purple : .purple.opacity(0.8))
            }
            .trackBackground { isEditing, _ in
                Color.gray
                    .opacity(0.5)
                    .frame(height: isEditing ? 20 : 10)
                    .clipShape(Capsule())
            }
            .topContent(topContent)
            .bottomContent(bottomContent)
            .leadingContent(leadingContent)
            .trailingContent(trailingContent)
    }
}

extension CapsuleSlider where TopContent == EmptyView,
                              BottomContent == EmptyView,
                              LeadingContent == EmptyView,
                              TrailingContent == EmptyView {

    init(progress: Binding<CGFloat>) {
        self.init(
            progress: progress,
            rate: .constant(1),
            topContent: { EmptyView() },
            bottomContent: { EmptyView() },
            leadingContent: { EmptyView() },
            trailingContent: {EmptyView() },
            onEditingChanged: { _ in }
        )
    }
}

extension CapsuleSlider {
    
    func topContent<C: View>(@ViewBuilder _ content: @escaping () -> C) -> CapsuleSlider<C, BottomContent, LeadingContent, TrailingContent> {
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
    
    func bottomContent<C: View>(@ViewBuilder _ content: @escaping () -> C) -> CapsuleSlider<TopContent, C, LeadingContent, TrailingContent> {
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
    
    func leadingContent<C: View>(@ViewBuilder _ content: @escaping () -> C) -> CapsuleSlider<TopContent, BottomContent, C, TrailingContent> {
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
    
    func trailingContent<C: View>(@ViewBuilder _ content: @escaping () -> C) -> CapsuleSlider<TopContent, BottomContent, LeadingContent, C> {
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
