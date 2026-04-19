//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

// This component based on https://github.com/SwiftUIKit/Marquee

import SwiftUI

struct Marquee<Content: View>: View {

    enum ResetType {
        case bounce
        case loop
    }

    @Environment(\.isFocused)
    private var isFocused: Bool

    @State
    private var contentSize: CGSize = .zero
    @State
    private var isAppear = false
    @State
    private var isAnimating = false

    private let axis: Axis
    private let resetType: ResetType
    private let speed: CGFloat
    private let delay: Double
    private let gap: CGFloat
    private let animateWhenFocused: Bool
    private let fade: CGFloat

    private let content: Content

    var body: some View {
        switch axis {
        case .horizontal:
            horizontalBody
        case .vertical:
            verticalBody
        }
    }

    // MARK: - Horizontal

    private var horizontalBody: some View {
        ViewThatFits(in: .horizontal) {
            content

            GeometryReader { proxy in
                VStack(alignment: .leading) {
                    if isAppear {
                        ZStack {
                            content
                                .onSizeChanged { size, _ in
                                    let widthChanged = self.contentSize.width != size.width
                                    self.contentSize = size

                                    if widthChanged {
                                        resetAnimation(proxy: proxy)
                                    }
                                }
                                .fixedSize()
                                .marqueeOffset(x: offsetX(proxy: proxy), y: 0)
                                .frame(maxHeight: .infinity)

                            if resetType == .loop, contentSize.width >= proxy.size.width {
                                content
                                    .fixedSize()
                                    .marqueeOffset(
                                        x: offsetX(proxy: proxy) + contentSize.width + gap(proxy),
                                        y: 0
                                    )
                                    .frame(maxHeight: .infinity)
                            }
                        }
                    }
                }
                .padding(.leading, fade)
                .onAppear {
                    // There is the possibility that `proxy.size` is `.zero` on `onAppear`. This can happen e.g.
                    // inside a `NavigationView` or within a `.sheet`. In those cases we do not want to
                    // initialize the animation yet as we need the proper width first.
                    // This use-case is handled by reacting to changes to `proxy.size.width` below.
                    guard proxy.size.width != .zero else {
                        return
                    }

                    initializeAnimation(proxy: proxy)
                }
                .backport
                .onChange(of: proxy.size.width) {
                    guard !isAppear, proxy.size.width != .zero else {
                        return
                    }

                    initializeAnimation(proxy: proxy)
                }
                .backport
                .onChange(of: isFocused) { _, newFocused in
                    resetAnimation(proxy: proxy, isFocused: newFocused)
                }
                .backport
                .onChange(of: speed) { _, newSpeed in
                    resetAnimation(proxy: proxy, speed: newSpeed)
                }
                .backport
                .onChange(of: delay) { _, newDelay in
                    resetAnimation(proxy: proxy, delay: newDelay)
                }
                .onDisappear {
                    self.isAppear = false
                }
            }
            .frame(height: contentSize.height)
            .clipped()
            .mask {
                GeometryReader { proxy in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: fade / proxy.size.width),
                            .init(color: .black, location: 1 - (fade / proxy.size.width)),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            }
            .padding(.leading, -fade)
        }
    }

    // MARK: - Vertical

    private var verticalBody: some View {
        ViewThatFits(in: .vertical) {
            content

            GeometryReader { proxy in
                VStack(alignment: .leading) {
                    if isAppear {
                        content
                            .onSizeChanged { size, _ in
                                let heightChanged = self.contentSize.height != size.height
                                self.contentSize = size

                                if heightChanged {
                                    resetAnimation(proxy: proxy)
                                }
                            }
                            .fixedSize(horizontal: false, vertical: true)
                            .marqueeOffset(x: 0, y: offsetY(proxy: proxy))
                    }
                }
                .onAppear {
                    guard proxy.size.height != .zero else {
                        return
                    }

                    initializeAnimation(proxy: proxy)
                }
                .backport
                .onChange(of: proxy.size.height) {
                    guard !isAppear, proxy.size.height != .zero else {
                        return
                    }

                    initializeAnimation(proxy: proxy)
                }
                .onDisappear {
                    self.isAppear = false
                }
                .backport
                .onChange(of: isFocused) { _, newValue in
                    resetAnimation(proxy: proxy, isFocused: newValue)
                }
            }
            .padding(.top, fade)
            .clipped()
            .mask {
                GeometryReader { proxy in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: fade / proxy.size.height),
                            .init(color: .black, location: 1 - (fade / proxy.size.height)),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .padding(.top, -fade)
        }
    }

    // MARK: - Animation

    private func initializeAnimation(proxy: GeometryProxy) {
        isAppear = true
        resetAnimation(proxy: proxy)
    }

    private func offsetX(proxy: GeometryProxy) -> CGFloat {
        if isAnimating {
            switch resetType {
            case .loop:
                -(contentSize.width + gap(proxy))
            case .bounce:
                -(contentSize.width - proxy.size.width)
            }
        } else {
            0
        }
    }

    private func offsetY(proxy: GeometryProxy) -> CGFloat {
        if isAnimating {
            switch resetType {
            case .loop:
                -(contentSize.height + gap(proxy))
            case .bounce:
                -(contentSize.height - proxy.size.height)
            }
        } else {
            0
        }
    }

    private func resetAnimation(
        proxy: GeometryProxy,
        speed: Double? = nil,
        delay: Double? = nil,
        isFocused: Bool? = nil
    ) {
        let speed = speed ?? self.speed
        let isFocused = isFocused ?? self.isFocused

        if speed == 0 || speed == Double.infinity || (animateWhenFocused && !isFocused) {
            stopAnimation()
        } else {
            startAnimation(
                speed: speed,
                delay: delay ?? self.delay,
                proxy: proxy
            )
        }
    }

    private func startAnimation(
        speed: Double,
        delay: Double,
        proxy: GeometryProxy
    ) {
        let distance: CGFloat
        let contentFits: Bool

        switch axis {
        case .horizontal:
            contentFits = contentSize.width < proxy.size.width
            distance = resetType == .loop
                ? contentSize.width + gap(proxy)
                : contentSize.width - proxy.size.width
        case .vertical:
            contentFits = contentSize.height <= proxy.size.height
            distance = resetType == .loop
                ? contentSize.height + gap(proxy)
                : contentSize.height - proxy.size.height
        }

        if contentFits {
            stopAnimation()
            return
        }

        withAnimation(.linear(duration: 0.005)) {
            self.isAnimating = false

            withAnimation(
                Animation
                    .linear(duration: distance / speed)
                    .delay(delay)
                    .repeatForever(autoreverses: resetType == .bounce)
            ) {
                self.isAnimating = true
            }
        }
    }

    private func gap(_ proxy: GeometryProxy) -> CGFloat {
        switch axis {
        case .horizontal:
            max(0, proxy.size.width - contentSize.width) + gap
        case .vertical:
            max(0, proxy.size.height - contentSize.height) + gap
        }
    }

    private func stopAnimation() {
        withAnimation(.linear(duration: 0.005)) {
            self.isAnimating = false
        }
    }
}

extension Marquee {

    /// Init from String
    init(
        _ title: String,
        axis: Axis = .horizontal,
        resetType: ResetType = .loop,
        speed: CGFloat = 60.0,
        delay: Double = 2.0,
        gap: CGFloat = 50.0,
        animateWhenFocused: Bool = false,
        fade: CGFloat = 10.0
    ) where Content == Text {
        self.axis = axis
        self.resetType = resetType
        self.speed = speed
        self.delay = delay
        self.gap = gap
        self.animateWhenFocused = animateWhenFocused
        self.fade = fade
        content = Text(title)
    }

    /// Init from View
    init(
        axis: Axis = .horizontal,
        resetType: ResetType = .loop,
        speed: CGFloat = 60.0,
        delay: Double = 2.0,
        gap: CGFloat = 50.0,
        animateWhenFocused: Bool = false,
        fade: CGFloat = 10.0,
        @ViewBuilder content: () -> Content
    ) {
        self.axis = axis
        self.resetType = resetType
        self.speed = speed
        self.delay = delay
        self.gap = gap
        self.animateWhenFocused = animateWhenFocused
        self.fade = fade
        self.content = content()
    }
}

// Reference:  https://swiftui-lab.com/swiftui-animations-part2/

private extension View {
    func marqueeOffset(x: CGFloat, y: CGFloat) -> some View {
        modifier(_OffsetEffect(offset: CGSize(width: x, height: y)))
    }
}

private struct _OffsetEffect: GeometryEffect {
    var offset: CGSize

    var animatableData: CGSize.AnimatableData {
        get { CGSize.AnimatableData(offset.width, offset.height) }
        set { offset = CGSize(width: newValue.first, height: newValue.second) }
    }

    func effectValue(size _: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: offset.width, y: offset.height))
    }
}
