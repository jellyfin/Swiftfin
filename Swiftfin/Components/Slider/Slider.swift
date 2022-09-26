//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

enum SliderGestureBehavior {
    case thumb
    case track
}

struct Slider<Track: View, TrackBackground: View, Thumb: View>: View {
    
    @Binding
    private var progress: CGFloat
    @State
    private var isEditing: Bool = false
    @State
    private var totalWidth: CGFloat = 0
    @State
    private var dragStartProgress: CGFloat = 0
    @State
    private var lastDragRate: CGFloat = 1
    @State
    private var currentTranslationStartLocation: CGPoint = .zero
    @State
    private var currentTranslation: CGFloat = 0
    @State
    private var needsTrackThumbFrame: Bool = false
    @State
    private var thumbSize: CGSize = .zero
    
    private var gestureBehavior: SliderGestureBehavior
    private var thumbHitPadding: CGFloat
    private var rate: (CGPoint) -> CGFloat
    private var track: (Bool, CGFloat) -> Track
    private var trackBackground: (Bool, CGFloat) -> TrackBackground
    private var thumb: (Bool, CGFloat) -> Thumb
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
                
                let dragRate = rate(CGPoint(x: value.startLocation.x - value.location.x, y: value.startLocation.y - value.location.y))
                if dragRate != lastDragRate {
                    dragStartProgress = progress
                    lastDragRate = dragRate
                    currentTranslationStartLocation = value.location
                }
                
                currentTranslation = (currentTranslationStartLocation.x - value.location.x) * dragRate
                
                let newProgress: CGFloat = dragStartProgress - currentTranslation / totalWidth
                progress = min(max(0, newProgress), 1)
            }
            .onEnded { value in
                isEditing = false
                onEditingChanged(false)
            }
    }

    var body: some View {
        VStack {
            Spacer()

            ZStack(alignment: .leading) {
                
                trackBackground(isEditing, progress)
                
                track(isEditing, progress)
                    .mask(alignment: .leading) {
                        Color.white
                            .frame(width: progress * totalWidth)
                    }
                
                thumb(isEditing, progress)
                    .if(gestureBehavior == .thumb) { view in
                        view.gesture(trackDrag)
                    }
                    .onSizeChanged { newSize in
                        thumbSize = newSize
                    }
                    .offset(x: progress * totalWidth - thumbSize.width / 2)
            }

            Spacer()
        }
        .onSizeChanged { size in
            totalWidth = size.width
        }
        .contentShape(Rectangle())
        .if(gestureBehavior == .track) { view in
            view.gesture(trackDrag)
        }
        .animation(progressAnimation, value: progress)
    }
}

extension Slider where Track == EmptyView, TrackBackground == EmptyView, Thumb == EmptyView {
    
    init(progress: Binding<CGFloat>) {
        self._progress = progress
        self.gestureBehavior = .thumb
        self.thumbHitPadding = 0
        self.rate = { _ in 1.0 }
        self.track = { _, _ in EmptyView() }
        self.trackBackground = { _, _ in EmptyView() }
        self.thumb = { _, _ in EmptyView() }
        self.onEditingChanged = { _ in }
        self.progressAnimation = .linear(duration: 0.02)
    }
}

extension Slider {
    
    func track<T>(@ViewBuilder _ track: @escaping (Bool, CGFloat) -> T) -> Slider<T, TrackBackground, Thumb> {
        Slider<T, TrackBackground, Thumb>(
            progress: _progress,
            gestureBehavior: gestureBehavior,
            thumbHitPadding: thumbHitPadding,
            rate: rate,
            track: track,
            trackBackground: trackBackground,
            thumb: thumb,
            onEditingChanged: onEditingChanged,
            progressAnimation: progressAnimation)
    }
    
    func trackBackground<T>(@ViewBuilder _ trackBackground: @escaping (Bool, CGFloat) -> T) -> Slider<Track, T, Thumb> {
        Slider<Track, T, Thumb>(
            progress: _progress,
            gestureBehavior: gestureBehavior,
            thumbHitPadding: thumbHitPadding,
            rate: rate,
            track: track,
            trackBackground: trackBackground,
            thumb: thumb,
            onEditingChanged: onEditingChanged,
            progressAnimation: progressAnimation)
    }
    
    func thumb<T>(@ViewBuilder _ thumb: @escaping (Bool, CGFloat) -> T) -> Slider<Track, TrackBackground, T> {
        Slider<Track, TrackBackground, T>(
            progress: _progress,
            gestureBehavior: gestureBehavior,
            thumbHitPadding: thumbHitPadding,
            rate: rate,
            track: track,
            trackBackground: trackBackground,
            thumb: thumb,
            onEditingChanged: onEditingChanged,
            progressAnimation: progressAnimation)
    }
    
    func onEditingChanged(_ action: @escaping (Bool) -> Void) -> Self {
        copy(modifying: \.onEditingChanged, with: action)
    }
    
    func gestureBehavior(_ gestureBehavior: SliderGestureBehavior) -> Self {
        copy(modifying: \.gestureBehavior, with: gestureBehavior)
    }
    
    func rate(_ rate: @escaping (CGPoint) -> CGFloat) -> Self {
        copy(modifying: \.rate, with: rate)
    }
    
    func progressAnimation(_ animation: Animation) -> Self {
        copy(modifying: \.progressAnimation, with: animation)
    }
}
