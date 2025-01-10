//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct Slider: View {

    enum Behavior {
        case thumb
        case track
    }

    @Binding
    private var progress: CGFloat

    @State
    private var isEditing: Bool = false
    @State
    private var totalWidth: CGFloat = 0
    @State
    private var dragStartProgress: CGFloat = 0
    @State
    private var currentTranslationStartLocation: CGPoint = .zero
    @State
    private var currentTranslation: CGFloat = 0
    @State
    private var thumbSize: CGSize = .zero

    private var sliderBehavior: Behavior
    private var trackGesturePadding: EdgeInsets
    private var track: () -> any View
    private var trackBackground: () -> any View
    private var trackMask: () -> any View
    private var thumb: () -> any View
    private var topContent: () -> any View
    private var bottomContent: () -> any View
    private var leadingContent: () -> any View
    private var trailingContent: () -> any View
    private var onEditingChanged: (Bool) -> Void
    private var progressAnimation: Animation

    private var trackDrag: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                if !isEditing {
                    isEditing = true
                    onEditingChanged(true)
                    dragStartProgress = progress
                    currentTranslationStartLocation = value.location
                    currentTranslation = 0
                }

                currentTranslation = currentTranslationStartLocation.x - value.location.x

                let newProgress: CGFloat = dragStartProgress - currentTranslation / totalWidth
                progress = min(max(0, newProgress), 1)
            }
            .onEnded { _ in
                isEditing = false
                onEditingChanged(false)
            }
    }

    var body: some View {
        HStack(alignment: .sliderCenterAlignmentGuide, spacing: 0) {
            leadingContent()
                .eraseToAnyView()
                .alignmentGuide(.sliderCenterAlignmentGuide) { context in
                    context[VerticalAlignment.center]
                }

            VStack(spacing: 0) {
                topContent()
                    .eraseToAnyView()

                ZStack(alignment: .leading) {

                    ZStack {
                        trackBackground()
                            .eraseToAnyView()

                        track()
                            .eraseToAnyView()
                            .mask(alignment: .leading) {
                                Color.white
                                    .frame(width: progress * totalWidth)
                            }
                    }
                    .mask {
                        trackMask()
                            .eraseToAnyView()
                    }

                    thumb()
                        .eraseToAnyView()
                        .if(sliderBehavior == .thumb) { view in
                            view.gesture(trackDrag)
                        }
                        .onSizeChanged { newSize in
                            thumbSize = newSize
                        }
                        .offset(x: progress * totalWidth - thumbSize.width / 2)
                }
                .onSizeChanged { size in
                    totalWidth = size.width
                }
                .if(sliderBehavior == .track) { view in
                    view.overlay {
                        Color.clear
                            .padding(trackGesturePadding)
                            .contentShape(Rectangle())
                            .highPriorityGesture(trackDrag)
                    }
                }
                .alignmentGuide(.sliderCenterAlignmentGuide) { context in
                    context[VerticalAlignment.center]
                }

                bottomContent()
                    .eraseToAnyView()
            }

            trailingContent()
                .eraseToAnyView()
                .alignmentGuide(.sliderCenterAlignmentGuide) { context in
                    context[VerticalAlignment.center]
                }
        }
        .animation(progressAnimation, value: progress)
        .animation(.linear(duration: 0.2), value: isEditing)
    }
}

extension Slider {

    init(progress: Binding<CGFloat>) {
        self.init(
            progress: progress,
            sliderBehavior: .track,
            trackGesturePadding: .zero,
            track: { EmptyView() },
            trackBackground: { EmptyView() },
            trackMask: { EmptyView() },
            thumb: { EmptyView() },
            topContent: { EmptyView() },
            bottomContent: { EmptyView() },
            leadingContent: { EmptyView() },
            trailingContent: { EmptyView() },
            onEditingChanged: { _ in },
            progressAnimation: .linear(duration: 0.05)
        )
    }

    func track(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.track, with: content)
    }

    func trackBackground(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.trackBackground, with: content)
    }

    func trackMask(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.trackMask, with: content)
    }

    func thumb(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.thumb, with: content)
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

    func trackGesturePadding(_ insets: EdgeInsets) -> Self {
        copy(modifying: \.trackGesturePadding, with: insets)
    }

    func onEditingChanged(_ action: @escaping (Bool) -> Void) -> Self {
        copy(modifying: \.onEditingChanged, with: action)
    }

    func gestureBehavior(_ sliderBehavior: Behavior) -> Self {
        copy(modifying: \.sliderBehavior, with: sliderBehavior)
    }

    func progressAnimation(_ animation: Animation) -> Self {
        copy(modifying: \.progressAnimation, with: animation)
    }
}
