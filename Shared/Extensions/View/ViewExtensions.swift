//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import SwiftUI

// TODO: organize

extension View {

    @inlinable
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }

    // TODO: rename `invertedMask`?
    func inverseMask(alignment: Alignment = .center, @ViewBuilder _ content: @escaping () -> some View) -> some View {
        mask(alignment: alignment) {
            content()
                .foregroundColor(.black)
                .background(.white)
                .compositingGroup()
                .luminanceToAlpha()
        }
    }

    /// - Important: Do *not* use this modifier for dynamically showing/hiding views.
    ///              Instead, use a native `if` statement.
    @ViewBuilder
    @inlinable
    func `if`<Content: View>(_ condition: Bool, @ViewBuilder transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// - Important: Do *not* use this modifier for dynamically showing/hiding views.
    ///              Instead, use a native `if/else` statement.
    @ViewBuilder
    @inlinable
    func `if`<Content: View>(
        _ condition: Bool,
        @ViewBuilder transformIf: (Self) -> Content,
        @ViewBuilder transformElse: (Self) -> Content
    ) -> some View {
        if condition {
            transformIf(self)
        } else {
            transformElse(self)
        }
    }

    /// - Important: Do *not* use this modifier for dynamically showing/hiding views.
    ///              Instead, use a native `if let` statement.
    @ViewBuilder
    @inlinable
    func ifLet<Value, Content: View>(
        _ value: Value?,
        @ViewBuilder transform: (Self, Value) -> Content
    ) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }

    /// - Important: Do *not* use this modifier for dynamically showing/hiding views.
    ///              Instead, use a native `if let/else` statement.
    @ViewBuilder
    @inlinable
    func ifLet<Value, Content: View>(
        _ value: Value?,
        @ViewBuilder transformIf: (Self, Value) -> Content,
        @ViewBuilder transformElse: (Self) -> Content
    ) -> some View {
        if let value {
            transformIf(self, value)
        } else {
            transformElse(self)
        }
    }

    /// Applies the aspect ratio and corner radius for the given `PosterType`
    @ViewBuilder
    func posterStyle(_ type: PosterType) -> some View {
        switch type {
        case .portrait:
            aspectRatio(2 / 3, contentMode: .fill)
            #if !os(tvOS)
                .cornerRadius(ratio: 0.0375, of: \.width)
            #endif
        case .landscape:
            aspectRatio(1.77, contentMode: .fill)
            #if !os(tvOS)
                .cornerRadius(ratio: 1 / 30, of: \.width)
            #endif
        }
    }

    // TODO: remove
    @inlinable
    func padding2(_ edges: Edge.Set = .all) -> some View {
        padding(edges).padding(edges)
    }

    func scrollViewOffset(_ scrollViewOffset: Binding<CGFloat>) -> some View {
        modifier(ScrollViewOffsetModifier(scrollViewOffset: scrollViewOffset))
    }

    func backgroundParallaxHeader<Header: View>(
        _ scrollViewOffset: Binding<CGFloat>,
        height: CGFloat,
        multiplier: CGFloat = 1,
        @ViewBuilder header: @escaping () -> Header
    ) -> some View {
        modifier(BackgroundParallaxHeaderModifier(scrollViewOffset, height: height, multiplier: multiplier, header: header))
    }

    func bottomEdgeGradient(bottomColor: Color) -> some View {
        modifier(BottomEdgeGradientModifier(bottomColor: bottomColor))
    }

    func posterShadow() -> some View {
        shadow(radius: 4, y: 2)
    }

    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }

    /// Apply a corner radius as a ratio of a view's side
    func cornerRadius(ratio: CGFloat, of side: KeyPath<CGSize, CGFloat>, corners: UIRectCorner = .allCorners) -> some View {
        modifier(RatioCornerRadiusModifier(corners: corners, ratio: ratio, side: side))
    }

    func onFrameChanged(_ onChange: @escaping (CGRect) -> Void) -> some View {
        background {
            GeometryReader { reader in
                Color.clear
                    .preference(key: FramePreferenceKey.self, value: reader.frame(in: .global))
            }
        }
        .onPreferenceChange(FramePreferenceKey.self, perform: onChange)
    }

    func frame(_ binding: Binding<CGRect>) -> some View {
        onFrameChanged { newFrame in
            binding.wrappedValue = newFrame
        }
    }

    // TODO: have x/y tracked binding

    func onLocationChanged(_ onChange: @escaping (CGPoint) -> Void) -> some View {
        background {
            GeometryReader { reader in
                Color.clear
                    .preference(
                        key: LocationPreferenceKey.self,
                        value: CGPoint(x: reader.frame(in: .global).midX, y: reader.frame(in: .global).midY)
                    )
            }
        }
        .onPreferenceChange(LocationPreferenceKey.self, perform: onChange)
    }

    func location(_ binding: Binding<CGPoint>) -> some View {
        onLocationChanged { newLocation in
            binding.wrappedValue = newLocation
        }
    }

    // TODO: have width/height tracked binding

    func onSizeChanged(_ onChange: @escaping (CGSize) -> Void) -> some View {
        background {
            GeometryReader { reader in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: reader.size)
            }
        }
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }

    func size(_ binding: Binding<CGSize>) -> some View {
        onSizeChanged { newSize in
            binding.wrappedValue = newSize
        }
    }

    func copy<Value>(modifying keyPath: WritableKeyPath<Self, Value>, with newValue: Value) -> Self {
        var copy = self
        copy[keyPath: keyPath] = newValue
        return copy
    }

    // TODO: rename isVisible

    /// - Important: Do not use this to add or remove a view from the view heirarchy.
    ///              Use a conditional statement instead.
    @inlinable
    func visible(_ isVisible: Bool) -> some View {
        opacity(isVisible ? 1 : 0)
    }

    func blurred(style: UIBlurEffect.Style = .regular) -> some View {
        overlay {
            BlurView(style: style)
        }
    }

    /// Applies the `.palette` symbol rendering mode and a foreground style
    /// where the primary style is the passed `Color`'s `overlayColor` and the
    /// secondary style is the passed `Color`.
    ///
    /// If `color == nil`, then `accentColor` from the environment is used.
    func paletteOverlayRendering(color: Color? = nil) -> some View {
        modifier(PaletteOverlayRenderingModifier(color: color))
    }

    @ViewBuilder
    func navigationBarHidden() -> some View {
        if #available(iOS 16, tvOS 16, *) {
            toolbar(.hidden, for: .navigationBar)
        } else {
            navigationBarHidden(true)
        }
    }

    func asAttributeStyle(_ style: AttributeViewModifier.Style) -> some View {
        modifier(AttributeViewModifier(style: style))
    }

    // TODO: rename `blurredFullScreenCover`
    func blurFullScreenCover(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> any View
    ) -> some View {
        fullScreenCover(isPresented: isPresented, onDismiss: onDismiss) {
            ZStack {
                BlurView()

                content()
                    .eraseToAnyView()
            }
            .ignoresSafeArea()
        }
    }

    func onScenePhase(_ phase: ScenePhase, _ action: @escaping () -> Void) -> some View {
        modifier(ScenePhaseChangeModifier(phase: phase, action: action))
    }

    func edgePadding(_ edges: Edge.Set = .all) -> some View {
        padding(edges, EdgeInsets.defaultEdgePadding)
    }

    var backport: Backport<Self> {
        Backport(content: self)
    }

    /// Perform an action on the final disappearance of a `View`.
    func onFinalDisappear(perform action: @escaping () -> Void) -> some View {
        modifier(OnFinalDisappearModifier(action: action))
    }

    /// Perform an action before the first appearance of a `View`.
    func onFirstAppear(perform action: @escaping () -> Void) -> some View {
        modifier(OnFirstAppearModifier(action: action))
    }

    /// Perform an action as a view appears given the time interval
    /// from when this view last disappeared.
    func afterLastDisappear(perform action: @escaping (TimeInterval) -> Void) -> some View {
        modifier(AfterLastDisappearModifier(action: action))
    }

    func topBarTrailing(@ViewBuilder content: @escaping () -> some View) -> some View {
        toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                content()
            }
        }
    }

    func onNotification(_ name: NSNotification.Name, perform action: @escaping () -> Void) -> some View {
        modifier(
            OnReceiveNotificationModifier(
                notification: name,
                onReceive: action
            )
        )
    }
}
