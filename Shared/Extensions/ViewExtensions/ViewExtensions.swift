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

    func inverseMask<M: View>(_ mask: M) -> some View {
        // exchange foreground and background
        let inversed = mask
            .foregroundColor(.black) // hide foreground
            .background(Color.white) // let the background stand out
            .compositingGroup()
            .luminanceToAlpha()
        return self.mask(inversed)
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

    // TODO: Simplify plethora of calls
    // TODO: Centralize math
    // TODO: Move poster stuff to own file
    // TODO: Figure out proper handling of corner radius for tvOS buttons
    func posterStyle(type: PosterType, width: CGFloat) -> some View {
        Group {
            switch type {
            case .portrait:
                self.portraitPoster(width: width)
            case .landscape:
                self.landscapePoster(width: width)
            }
        }
    }

    func posterStyle(type: PosterType, height: CGFloat) -> some View {
        Group {
            switch type {
            case .portrait:
                self.portraitPoster(height: height)
            case .landscape:
                self.landscapePoster(height: height)
            }
        }
    }

    private func portraitPoster(width: CGFloat) -> some View {
        frame(width: width, height: width * 1.5)
            .cornerRadius((width * 1.5) / 40)
    }

    private func landscapePoster(width: CGFloat) -> some View {
        frame(width: width, height: width / 1.77)
        #if !os(tvOS)
            .cornerRadius(width / 30)
        #endif
    }

    private func portraitPoster(height: CGFloat) -> some View {
        portraitPoster(width: height / 1.5)
    }

    private func landscapePoster(height: CGFloat) -> some View {
        landscapePoster(width: height * 1.77)
    }

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

    @inlinable
    func visible(_ isVisible: Bool) -> some View {
        opacity(isVisible ? 1 : 0)
//        modifier(VisibilityModifier(isVisible: isVisible))
    }

    func blurred(style: UIBlurEffect.Style = .regular) -> some View {
        modifier(BlurViewModifier(style: style))
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

    func inBasicNavigationCoordinatable() -> BasicNavigationViewCoordinator {
        BasicNavigationViewCoordinator {
            self
        }
    }
}
