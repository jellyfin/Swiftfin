//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
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

    func inverseMask(alignment: Alignment = .center, _ content: @escaping () -> some View) -> some View {
        mask(alignment: alignment) {
            content()
                .foregroundColor(.black)
                .background(.white)
                .compositingGroup()
                .luminanceToAlpha()
        }
    }

    // From: https://www.avanderlee.com/swiftui/conditional-view-modifier/
    @ViewBuilder
    @inlinable
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder
    @inlinable
    func `if`<Content: View>(_ condition: Bool, transformIf: (Self) -> Content, transformElse: (Self) -> Content) -> some View {
        if condition {
            transformIf(self)
        } else {
            transformElse(self)
        }
    }

    // TODO: Don't apply corner radius on tvOS because buttons handle themselves, add new modifier for setting corner radius of poster type
    @ViewBuilder
    func posterStyle(_ type: PosterType) -> some View {
        switch type {
        case .portrait:
            aspectRatio(2 / 3, contentMode: .fit)
                .cornerRadius(ratio: 0.0375, of: \.width)
        case .landscape:
            aspectRatio(1.77, contentMode: .fit)
                .cornerRadius(ratio: 1 / 30, of: \.width)
        }
    }

    // TODO: switch to padding(multiplier: 2)
    @inlinable
    func padding2(_ edges: Edge.Set = .all) -> some View {
        padding(edges).padding(edges)
    }

    /// Applies the default system padding a number of times with a multiplier
    func padding(multiplier: Int, _ edges: Edge.Set = .all) -> some View {
        precondition(multiplier > 0, "Multiplier must be > 0")

        return modifier(PaddingMultiplierModifier(edges: edges, multiplier: multiplier))
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

    /// Apply a corner radius as a ratio of a side of the view's size
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

    func onSizeChanged(_ onChange: @escaping (CGSize) -> Void) -> some View {
        background {
            GeometryReader { reader in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: reader.size)
            }
        }
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }

    func copy<Value>(modifying keyPath: WritableKeyPath<Self, Value>, with newValue: Value) -> Self {
        var copy = self
        copy[keyPath: keyPath] = newValue
        return copy
    }

    @ViewBuilder
    func hideSystemOverlays() -> some View {
        if #available(iOS 16, tvOS 16, *) {
            persistentSystemOverlays(.hidden)
        } else {
            self
        }
    }

    // TODO: rename isVisible
    @inlinable
    func visible(_ isVisible: Bool) -> some View {
        opacity(isVisible ? 1 : 0)
    }

    func blurred(style: UIBlurEffect.Style = .regular) -> some View {
        overlay {
            BlurView(style: style)
        }
    }

    func accentSymbolRendering(accentColor: Color = Defaults[.accentColor]) -> some View {
        symbolRenderingMode(.palette)
            .foregroundStyle(accentColor.overlayColor, accentColor)
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
}
