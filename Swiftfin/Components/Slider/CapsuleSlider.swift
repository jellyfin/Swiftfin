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
    @State
    private var isEditing: Bool = false
    private var topContent: () -> TopContent
    private var bottomContent: () -> BottomContent
    private var leadingContent: () -> LeadingContent
    private var trailingContent: () -> TrailingContent
    private var onEditingChanged: (Bool) -> Void
    private var onRateRequested: (CGFloat) -> Void

    var body: some View {
        Slider(progress: $progress)
            .gestureBehavior(.track)
            .trackGesturePadding(50)
            .rate { pointOffset in
                if abs(pointOffset.y) > 50 {
                    onRateRequested(0.01)
                    return 0.01
                } else {
                    onRateRequested(1)
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
            topContent: { EmptyView() },
            bottomContent: { EmptyView() },
            leadingContent: { EmptyView() },
            trailingContent: {EmptyView() },
            onEditingChanged: { _ in },
            onRateRequested: { _ in }
        )
    }
}

extension CapsuleSlider {
    
    func topContent<C: View>(@ViewBuilder _ content: @escaping () -> C) -> CapsuleSlider<C, BottomContent, LeadingContent, TrailingContent> {
        .init(
            progress: $progress,
            topContent: content,
            bottomContent: bottomContent,
            leadingContent: leadingContent,
            trailingContent: trailingContent,
            onEditingChanged: onEditingChanged,
            onRateRequested: onRateRequested
        )
    }
    
    func bottomContent<C: View>(@ViewBuilder _ content: @escaping () -> C) -> CapsuleSlider<TopContent, C, LeadingContent, TrailingContent> {
        .init(
            progress: $progress,
            topContent: topContent,
            bottomContent: content,
            leadingContent: leadingContent,
            trailingContent: trailingContent,
            onEditingChanged: onEditingChanged,
            onRateRequested: onRateRequested
        )
    }
    
    func leadingContent<C: View>(@ViewBuilder _ content: @escaping () -> C) -> CapsuleSlider<TopContent, BottomContent, C, TrailingContent> {
        .init(
            progress: $progress,
            topContent: topContent,
            bottomContent: bottomContent,
            leadingContent: content,
            trailingContent: trailingContent,
            onEditingChanged: onEditingChanged,
            onRateRequested: onRateRequested
        )
    }
    
    func trailingContent<C: View>(@ViewBuilder _ content: @escaping () -> C) -> CapsuleSlider<TopContent, BottomContent, LeadingContent, C> {
        .init(
            progress: $progress,
            topContent: topContent,
            bottomContent: bottomContent,
            leadingContent: leadingContent,
            trailingContent: content,
            onEditingChanged: onEditingChanged,
            onRateRequested: onRateRequested
        )
    }
    
    func onEditingChanged(_ action: @escaping (Bool) -> Void) -> Self {
        copy(modifying: \.onEditingChanged, with: action)
    }
    
    func onRateRequested(_ action: @escaping (CGFloat) -> Void) -> Self {
        copy(modifying: \.onRateRequested, with: action)
    }
}
