//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: remove and just make into a thumb slider
// TODO: maybe make a base slider style that takes
//       the drag gesture

struct SwiftfinSlider: View {

    @Binding
    private var progress: Double

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

    private var trackGesturePadding: EdgeInsets
    private var track: () -> any View
    private var trackBackground: () -> any View
    private var trackMask: () -> any View
    private var thumb: () -> any View
    private var onEditingChanged: (Bool) -> Void

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
            VStack(spacing: 0) {

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
//                        .if(sliderBehavior == .thumb) { view in
//                            view.gesture(trackDrag)
//                        }
                        .gesture(trackDrag)
                        .onSizeChanged { newSize in
                            thumbSize = newSize
                        }
                        .offset(x: progress * totalWidth - thumbSize.width / 2)
                }
                .onSizeChanged { size in
                    totalWidth = size.width
                }
            }
//        .animation(.linear(duration: 0.05), value: progress)
//        .animation(.linear(duration: 0.2), value: isEditing)
    }
}

extension SwiftfinSlider {

    init(progress: Binding<Double>) {
        self.init(
            progress: progress,
            trackGesturePadding: .zero,
            track: { EmptyView() },
            trackBackground: { EmptyView() },
            trackMask: { EmptyView() },
            thumb: { EmptyView() },
            onEditingChanged: { _ in }
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

    func trackGesturePadding(_ insets: EdgeInsets) -> Self {
        copy(modifying: \.trackGesturePadding, with: insets)
    }

    func onEditingChanged(_ action: @escaping (Bool) -> Void) -> Self {
        copy(modifying: \.onEditingChanged, with: action)
    }
}
