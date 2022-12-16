//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

// TODO: organize

extension View {

    @inlinable
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }

    public func inverseMask<M: View>(_ mask: M) -> some View {
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
        self.frame(width: width, height: width * 1.5)
            .cornerRadius((width * 1.5) / 40)
    }

    private func landscapePoster(width: CGFloat) -> some View {
        self.frame(width: width, height: width / 1.77)
            .cornerRadius(width / 30)
    }

    private func portraitPoster(height: CGFloat) -> some View {
        self.portraitPoster(width: height / 1.5)
    }

    private func landscapePoster(height: CGFloat) -> some View {
        self.landscapePoster(width: height * 1.77)
    }

    @inlinable
    func padding2(_ edges: Edge.Set = .all) -> some View {
        self.padding(edges)
            .padding(edges)
    }

    func scrollViewOffset(_ scrollViewOffset: Binding<CGFloat>) -> some View {
        self.modifier(ScrollViewOffsetModifier(scrollViewOffset: scrollViewOffset))
    }

    func backgroundParallaxHeader<Header: View>(
        _ scrollViewOffset: Binding<CGFloat>,
        height: CGFloat,
        multiplier: CGFloat = 1,
        @ViewBuilder header: @escaping () -> Header
    ) -> some View {
        self.modifier(BackgroundParallaxHeaderModifier(scrollViewOffset, height: height, multiplier: multiplier, header: header))
    }

    func bottomEdgeGradient(bottomColor: Color) -> some View {
        self.modifier(BottomEdgeGradientModifier(bottomColor: bottomColor))
    }

    func posterShadow() -> some View {
        self.shadow(radius: 4, y: 2)
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
            self.persistentSystemOverlays(.hidden)
        } else {
            self
        }
    }
}
