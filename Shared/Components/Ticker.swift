//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

// This component based on https://github.com/SwiftUIKit/Marquee

import SwiftUI

private enum TickerState {
    case idle
    case animating
}

struct Ticker<Content: View>: View {

    @State
    private var contentSize: CGSize = .zero
    @State
    private var isAppear = false
    @State
    private var state: TickerState = .idle

    private let speed: CGFloat
    private let delay: Double
    private let fade: CGFloat

    private let content: Content

    init(
        speed: CGFloat = 30.0,
        delay: Double = 2.0,
        fade: CGFloat = 20.0,
        @ViewBuilder content: () -> Content
    ) {
        self.speed = speed
        self.delay = delay
        self.fade = fade
        self.content = content()
    }

    var body: some View {
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
                            .tickerOffset(y: offsetY(proxy: proxy))
                    } else {
                        EmptyView()
                    }
                }
                .onAppear {
                    // There is the possibility that `proxy.size` is `.zero` on `onAppear`. This can happen e.g.
                    // inside a `NavigationView` or within a `.sheet`. In those cases we do not want to
                    // initialize the animation yet as we need the proper height first.
                    // This use-case is handled by reacting to changes to `proxy.size.height` below.
                    guard proxy.size.height != .zero else {
                        return
                    }

                    initializeAnimation(proxy: proxy)
                }
                .onChange(of: proxy.size.height) { _ in
                    guard !isAppear, proxy.size.height != .zero else {
                        return
                    }

                    initializeAnimation(proxy: proxy)
                }
                .onDisappear {
                    self.isAppear = false
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

    private func initializeAnimation(proxy: GeometryProxy) {
        isAppear = true
        resetAnimation(proxy: proxy)
    }

    private func offsetY(proxy: GeometryProxy) -> CGFloat {
        switch state {
        case .idle:
            0
        case .animating:
            -(contentSize.height - proxy.size.height)
        }
    }

    private func resetAnimation(
        proxy: GeometryProxy,
        speed: Double? = nil,
        delay: Double? = nil
    ) {
        let speed = speed ?? self.speed

        if speed == 0 || speed == Double.infinity {
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
        let contentFits = contentSize.height <= proxy.size.height
        if contentFits {
            stopAnimation()
            return
        }

        let distance = contentSize.height - proxy.size.height
        let duration = distance / speed

        withAnimation(.linear(duration: 0.005)) {
            self.state = .idle
            withAnimation(
                Animation
                    .linear(duration: duration)
                    .delay(delay)
                    .repeatForever(autoreverses: true)
            ) {
                self.state = .animating
            }
        }
    }

    private func stopAnimation() {
        withAnimation(.linear(duration: 0.005)) {
            self.state = .idle
        }
    }
}

// Reference:  https://swiftui-lab.com/swiftui-animations-part2/

private extension View {
    func tickerOffset(y: CGFloat) -> some View {
        modifier(_TickerOffsetEffect(offset: y))
    }
}

private struct _TickerOffsetEffect: GeometryEffect {
    var offset: CGFloat

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func effectValue(size _: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 0, y: offset))
    }
}
