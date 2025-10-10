//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

// This component based on https://github.com/SwiftUIKit/Marquee

import SwiftUI

private enum MarqueeState {
    case idle
    case animating
}

struct Marquee<Content>: View where Content: View {

    @Environment(\.isFocused)
    private var isFocused: Bool

    @State
    private var contentSize: CGSize = .zero
    @State
    private var isAppear = false
    @State
    private var state: MarqueeState = .idle

    private let speed: CGFloat
    private let delay: Double
    private let gap: CGFloat
    private let animateWhenFocused: Bool
    private let fade: CGFloat

    private let content: Content

    init(
        _ title: String,
        speed: CGFloat = 60.0,
        delay: Double = 2.0,
        gap: CGFloat = 50.0,
        animateWhenFocused: Bool = false,
        fade: CGFloat = 10.0
    ) where Content == Text {
        self.speed = speed
        self.delay = delay
        self.gap = gap
        self.animateWhenFocused = animateWhenFocused
        self.fade = fade
        content = Text(title)
    }

    var body: some View {
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

                            if contentSize.width >= proxy.size.width {
                                content
                                    .fixedSize()
                                    .marqueeOffset(
                                        x: offsetX(proxy: proxy) + contentSize.width + gap(proxy),
                                        y: 0
                                    )
                                    .frame(maxHeight: .infinity)
                            }
                        }
                    } else {
                        EmptyView()
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
                .onChange(of: proxy.size.width) { _ in
                    guard !isAppear, proxy.size.width != .zero else {
                        return
                    }

                    initializeAnimation(proxy: proxy)
                }
                .onDisappear {
                    self.isAppear = false
                }
                .onChange(of: isFocused) { newFocused in
                    resetAnimation(proxy: proxy, isFocused: newFocused)
                }
                .onChange(of: speed) { newSpeed in
                    resetAnimation(proxy: proxy, speed: newSpeed)
                }
                .onChange(of: delay) { newDelay in
                    resetAnimation(proxy: proxy, delay: newDelay)
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

    private func initializeAnimation(proxy: GeometryProxy) {
        isAppear = true
        resetAnimation(proxy: proxy)
    }

    private func offsetX(proxy: GeometryProxy) -> CGFloat {
        switch state {
        case .idle:
            return 0
        case .animating:
            return -(contentSize.width + gap(proxy))
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
        let contentFits = contentSize.width < proxy.size.width
        if contentFits {
            stopAnimation()
            return
        }

        let duration = (contentSize.width + gap(proxy)) / speed

        withAnimation(.linear(duration: 0.005)) {
            self.state = .idle
            withAnimation(
                Animation
                    .linear(duration: duration)
                    .delay(delay)
                    .repeatForever(autoreverses: false)
            ) {
                self.state = .animating
            }
        }
    }

    private func gap(_ proxy: GeometryProxy) -> CGFloat {
        max(0, proxy.size.width - contentSize.width) + gap
    }

    private func stopAnimation() {
        withAnimation(.linear(duration: 0.005)) {
            self.state = .idle
        }
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
