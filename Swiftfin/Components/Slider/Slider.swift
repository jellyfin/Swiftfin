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

struct Slider<Track: View, TrackBackground: View, Thumb: View, TopContent: View, BottomContent: View, LeadingContent: View, TrailingContent: View>: View {
    
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
    private var thumbSize: CGSize = .zero
    
    private var gestureBehavior: SliderGestureBehavior
    private var trackGesturePadding: CGFloat
    private var rate: (CGPoint) -> CGFloat
    private var track: (Bool, CGFloat) -> Track
    private var trackBackground: (Bool, CGFloat) -> TrackBackground
    private var thumb: (Bool, CGFloat) -> Thumb
    private var topContent: () -> TopContent
    private var bottomContent: () -> BottomContent
    private var leadingContent: () -> LeadingContent
    private var trailingContent: () -> TrailingContent
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
                
                let dragRate = rate(CGPoint(x: 0, y: value.startLocation.y - value.location.y))
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
        HStack(spacing: 0) {
            leadingContent()
            
            VStack(spacing: 0) {
                topContent()
                
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
                .onSizeChanged { size in
                    totalWidth = size.width
                }
                .if(gestureBehavior == .track) { view in
                    view.overlay {
                        Color.clear
                            .padding(.vertical, trackGesturePadding)
                            .contentShape(Rectangle())
                            .gesture(trackDrag)
                    }
                }
                
                bottomContent()
            }
            
            trailingContent()
        }
        .animation(progressAnimation, value: progress)
        .animation(.linear(duration: 0.1), value: isEditing)
    }
}

extension Slider where Track == EmptyView,
                        TrackBackground == EmptyView,
                        Thumb == EmptyView,
                        TopContent == EmptyView,
                        BottomContent == EmptyView,
                        LeadingContent == EmptyView,
                        TrailingContent == EmptyView {
    
    init(progress: Binding<CGFloat>) {
        self.init(
            progress: progress,
            gestureBehavior: .thumb,
            trackGesturePadding: 0,
            rate: { _ in 1.0 },
            track: { _, _ in EmptyView() },
            trackBackground: { _, _ in EmptyView() },
            thumb: { _, _ in EmptyView() },
            topContent: { EmptyView() },
            bottomContent: { EmptyView() },
            leadingContent: { EmptyView() },
            trailingContent: { EmptyView() },
            onEditingChanged: { _ in },
            progressAnimation: .linear(duration: 0.02)
        )
    }
}

extension Slider {
    
    func track<T>(@ViewBuilder _ track: @escaping (Bool, CGFloat) -> T) -> Slider<T, TrackBackground, Thumb, TopContent, BottomContent, LeadingContent, TrailingContent> {
        .init(
            progress: _progress,
            gestureBehavior: gestureBehavior,
            trackGesturePadding: trackGesturePadding,
            rate: rate,
            track: track,
            trackBackground: trackBackground,
            thumb: thumb,
            topContent: topContent,
            bottomContent: bottomContent,
            leadingContent: leadingContent,
            trailingContent: trailingContent,
            onEditingChanged: onEditingChanged,
            progressAnimation: progressAnimation)
    }
    
    func trackBackground<T>(@ViewBuilder _ trackBackground: @escaping (Bool, CGFloat) -> T) -> Slider<Track, T, Thumb, TopContent, BottomContent, LeadingContent, TrailingContent> {
        .init(
            progress: _progress,
            gestureBehavior: gestureBehavior,
            trackGesturePadding: trackGesturePadding,
            rate: rate,
            track: track,
            trackBackground: trackBackground,
            thumb: thumb,
            topContent: topContent,
            bottomContent: bottomContent,
            leadingContent: leadingContent,
            trailingContent: trailingContent,
            onEditingChanged: onEditingChanged,
            progressAnimation: progressAnimation)
    }
    
    func thumb<T>(@ViewBuilder _ thumb: @escaping (Bool, CGFloat) -> T) -> Slider<Track, TrackBackground, T, TopContent, BottomContent, LeadingContent, TrailingContent> {
        .init(
            progress: _progress,
            gestureBehavior: gestureBehavior,
            trackGesturePadding: trackGesturePadding,
            rate: rate,
            track: track,
            trackBackground: trackBackground,
            thumb: thumb,
            topContent: topContent,
            bottomContent: bottomContent,
            leadingContent: leadingContent,
            trailingContent: trailingContent,
            onEditingChanged: onEditingChanged,
            progressAnimation: progressAnimation)
    }
    
    func topContent<T>(@ViewBuilder _ topContent: @escaping () -> T) -> Slider<Track, TrackBackground, Thumb, T, BottomContent, LeadingContent, TrailingContent> {
        .init(
            progress: _progress,
            gestureBehavior: gestureBehavior,
            trackGesturePadding: trackGesturePadding,
            rate: rate,
            track: track,
            trackBackground: trackBackground,
            thumb: thumb,
            topContent: topContent,
            bottomContent: bottomContent,
            leadingContent: leadingContent,
            trailingContent: trailingContent,
            onEditingChanged: onEditingChanged,
            progressAnimation: progressAnimation)
    }
    
    func bottomContent<T>(@ViewBuilder _ bottomContent: @escaping () -> T) -> Slider<Track, TrackBackground, Thumb, TopContent, T, LeadingContent, TrailingContent> {
        .init(
            progress: _progress,
            gestureBehavior: gestureBehavior,
            trackGesturePadding: trackGesturePadding,
            rate: rate,
            track: track,
            trackBackground: trackBackground,
            thumb: thumb,
            topContent: topContent,
            bottomContent: bottomContent,
            leadingContent: leadingContent,
            trailingContent: trailingContent,
            onEditingChanged: onEditingChanged,
            progressAnimation: progressAnimation)
    }
    
    func leadingContent<T>(@ViewBuilder _ leadingContent: @escaping () -> T) -> Slider<Track, TrackBackground, Thumb, TopContent, BottomContent, T, TrailingContent> {
        .init(
            progress: _progress,
            gestureBehavior: gestureBehavior,
            trackGesturePadding: trackGesturePadding,
            rate: rate,
            track: track,
            trackBackground: trackBackground,
            thumb: thumb,
            topContent: topContent,
            bottomContent: bottomContent,
            leadingContent: leadingContent,
            trailingContent: trailingContent,
            onEditingChanged: onEditingChanged,
            progressAnimation: progressAnimation)
    }
    
    func trailingContent<T>(@ViewBuilder _ trailingContent: @escaping () -> T) -> Slider<Track, TrackBackground, Thumb, TopContent, BottomContent, LeadingContent, T> {
        .init(
            progress: _progress,
            gestureBehavior: gestureBehavior,
            trackGesturePadding: trackGesturePadding,
            rate: rate,
            track: track,
            trackBackground: trackBackground,
            thumb: thumb,
            topContent: topContent,
            bottomContent: bottomContent,
            leadingContent: leadingContent,
            trailingContent: trailingContent,
            onEditingChanged: onEditingChanged,
            progressAnimation: progressAnimation)
    }
    
    func trackGesturePadding(_ padding: CGFloat) -> Self {
        copy(modifying: \.trackGesturePadding, with: padding)
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
