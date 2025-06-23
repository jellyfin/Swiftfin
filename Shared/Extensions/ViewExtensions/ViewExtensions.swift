//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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

    /// Applies the aspect ratio, corner radius, and border for the given `PosterType`
    @ViewBuilder
    func posterStyle(_ type: PosterDisplayType, contentMode: ContentMode = .fill) -> some View {
        switch type {
        case .landscape:
            aspectRatio(1.77, contentMode: contentMode)
            #if os(iOS)
                .posterBorder(ratio: 1 / 30, of: \.width)
                .cornerRadius(ratio: 1 / 30, of: \.width)
            #endif
        case .portrait:
            aspectRatio(2 / 3, contentMode: contentMode)
            #if os(iOS)
                .posterBorder(ratio: 0.0375, of: \.width)
                .cornerRadius(ratio: 0.0375, of: \.width)
            #endif
        }
    }

    // TODO: consolidate handling
    @ViewBuilder
    func squarePosterStyle(contentMode: ContentMode = .fill) -> some View {
        aspectRatio(1.0, contentMode: contentMode)
        #if os(iOS)
            .posterBorder(ratio: 0.0375, of: \.width)
            .cornerRadius(ratio: 0.0375, of: \.width)
        #endif
    }

    func posterBorder(ratio: CGFloat, of side: KeyPath<CGSize, CGFloat>) -> some View {
        modifier(OnSizeChangedModifier { size in
            overlay {
                RoundedRectangle(cornerRadius: size[keyPath: side] * ratio)
                    .stroke(
                        .white.opacity(0.10),
                        lineWidth: 2
                    )
                    .clipped()
            }
        })
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

    /// Error Message Alert
    func errorMessage(
        _ error: Binding<Error?>,
        dismissActions: (() -> Void)? = nil
    ) -> some View {
        modifier(ErrorMessageModifier(error: error, dismissActions: dismissActions))
    }

    /// Apply a corner radius as a ratio of a view's side
    func posterShadow() -> some View {
        shadow(radius: 4, y: 2)
    }

    @ViewBuilder
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        if corners == .allCorners {
            clipShape(RoundedRectangle(cornerRadius: radius))
        } else {
            clipShape(RoundedCorner(radius: radius, corners: corners))
        }
    }

    /// Apply a corner radius as a ratio of a view's side
    func cornerRadius(ratio: CGFloat, of side: KeyPath<CGSize, CGFloat>, corners: UIRectCorner = .allCorners) -> some View {
        modifier(OnSizeChangedModifier { size in
            cornerRadius(size[keyPath: side] * ratio, corners: corners)
        })
    }

    func onFrameChanged(perform action: @escaping (CGRect, EdgeInsets) -> Void) -> some View {
        onGeometryChange(for: OnFrameChangedValue.self) { proxy in
            let frame = proxy.frame(in: .global)
            let safeAreaInsets = proxy.safeAreaInsets

            return .init(
                frame: frame,
                safeAreaInsets: safeAreaInsets
            )
        } action: { newValue in
            action(newValue.frame, newValue.safeAreaInsets)
        }
    }

    func trackingFrame(_ binding: Binding<CGRect>) -> some View {
        onFrameChanged { newFrame, _ in
            binding.wrappedValue = newFrame
        }
    }

    func onSizeChanged(perform action: @escaping (CGSize, EdgeInsets) -> Void) -> some View {
        onGeometryChange(for: OnFrameChangedValue.self) { proxy in
            let size = proxy.size
            let safeAreaInsets = proxy.safeAreaInsets

            return .init(
                frame: CGRect(origin: .zero, size: size),
                safeAreaInsets: safeAreaInsets
            )
        } action: { newValue in
            action(newValue.frame.size, newValue.safeAreaInsets)
        }
    }

    func trackingSize(
        _ sizeBinding: Binding<CGSize>,
        _ safeAreaInsetBinding: Binding<EdgeInsets> = .constant(.zero)
    ) -> some View {
        onSizeChanged {
            sizeBinding.wrappedValue = $0
            safeAreaInsetBinding.wrappedValue = $1
        }
    }

    func copy<Value>(modifying keyPath: WritableKeyPath<Self, Value>, with newValue: Value) -> Self {
        var copy = self
        copy[keyPath: keyPath] = newValue
        return copy
    }

    /// - Important: Do not use this to add or remove a view from the view heirarchy.
    ///              Use a conditional statement instead.
    @inlinable
    func isVisible(opacity: Double = 1.0, _ isVisible: Bool) -> some View {
        self.opacity(isVisible ? opacity : 0)
    }

    @inlinable
    @ViewBuilder
    func hidden(_ isHidden: Bool) -> some View {
        if isHidden {
            hidden()
        } else {
            self
        }
    }

    func blurred(style: UIBlurEffect.Style = .regular) -> some View {
        overlay {
            BlurView(style: style)
        }
    }

    func blurredFullScreenCover(
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
        modifier(OnScenePhaseChangedModifier(phase: phase, action: action))
    }

    func edgePadding(_ edges: Edge.Set = .all) -> some View {
        padding(edges, EdgeInsets.edgePadding)
    }

    var backport: Backport<Self> {
        Backport(content: self)
    }

    /// Perform an action on the final disappearance of a `View`.
    func onFinalDisappear(perform action: @escaping () -> Void) -> some View {
        modifier(OnFinalDisappearModifier(action: action))
    }

    /// Perform an action on the first appearance of a `View`.
    func onFirstAppear(perform action: @escaping () -> Void) -> some View {
        modifier(OnFirstAppearModifier(action: action))
    }

    /// Perform an action as the view appears given the time interval
    /// since the view last disappeared.
    func sinceLastDisappear(perform action: @escaping (TimeInterval) -> Void) -> some View {
        modifier(SinceLastDisappearModifier(action: action))
    }

    func topBarTrailing(@ViewBuilder content: @escaping () -> some View) -> some View {
        toolbar {
            ToolbarItemGroup(
                placement: .topBarTrailing,
                content: content
            )
        }
    }

    func onNotification<P>(_ key: Notifications.Key<P>, perform action: @escaping (P) -> Void) -> some View {
        modifier(
            OnReceiveNotificationModifier(
                key: key,
                onReceive: action
            )
        )
    }

    func scrollIfLargerThanContainer(padding: CGFloat = 0) -> some View {
        modifier(ScrollIfLargerThanContainerModifier(padding: padding))
    }

    func maskLinearGradient(
        @ArrayBuilder<OpacityLinearGradientModifier.Stop> stops: () -> [OpacityLinearGradientModifier.Stop]
    ) -> some View {
        modifier(OpacityLinearGradientModifier(stops: stops()))
    }

    // MARK: debug

    // Useful modifiers during development for layout without RocketSim

    #if DEBUG
    func debugBackground<S: ShapeStyle>(_ fill: S = .red.opacity(0.5)) -> some View {
        background {
            Rectangle()
                .fill(fill)
        }
    }

    func debugOverlay<S: ShapeStyle>(_ fill: S = .red.opacity(0.5)) -> some View {
        overlay {
            Rectangle()
                .fill(fill)
                .allowsHitTesting(false)
        }
    }

    func debugVLine<S: ShapeStyle>(_ fill: S) -> some View {
        overlay {
            Rectangle()
                .fill(fill)
                .frame(width: 4)
        }
    }

    func debugHLine<S: ShapeStyle>(_ fill: S) -> some View {
        overlay {
            Rectangle()
                .fill(fill)
                .frame(height: 4)
        }
    }

    func debugCross<S: ShapeStyle>(_ fill: S = .red) -> some View {
        debugVLine(fill)
            .debugHLine(fill)
    }
    #endif
}

private struct OnFrameChangedValue: Equatable {
    let frame: CGRect
    let safeAreaInsets: EdgeInsets
}
