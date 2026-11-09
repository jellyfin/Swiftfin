//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: make enhanced toasting system
//       - allow actions
//       - multiple toasts
//       - sizes, stacked
// TODO: symbol effects

// TODO: fix rapid fire animations
//       - have one that's presentation based, one just basic overlay?

/// A basic toasting container view that will present
/// given toasts on top of the given content.
struct OverlayToastView<Content: View>: View {

    @AdaptiveLayout
    private var viewLayout

    @StateObject
    private var toastProxy: ToastProxy

    private let content: Content

    private var topPadding: CGFloat {
        viewLayout.value(standard: 10, large: 60)
    }

    init(
        @ViewBuilder content: () -> Content
    ) {
        self._toastProxy = StateObject(wrappedValue: .init())
        self.content = content()
    }

    init(
        proxy: ToastProxy,
        @ViewBuilder content: () -> Content
    ) {
        self._toastProxy = StateObject(wrappedValue: proxy)
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .top) {
            content
                .environmentObject(toastProxy)

            if toastProxy.isPresenting {
                VStack {
                    OverlayToastContent()
                        .environmentObject(toastProxy)
                        .padding(.top, topPadding)
                        .transition(.offset(y: -20).combined(with: .opacity))

                    Spacer()
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: toastProxy.isPresenting)
    }
}

struct OverlayToastContent: View {

    @AdaptiveLayout
    private var viewLayout

    @EnvironmentObject
    private var proxy: ToastProxy

    var body: some View {
        #if os(tvOS)
        content
        #else
        Button {
            proxy.dismiss()
        } label: {
            content
        }
        .buttonStyle(ToastButtonStyle())
        #endif
    }

    private var content: some View {
        HStack {
            if let systemName = proxy.systemName {
                Image(systemName: systemName)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
            }

            proxy.title
                .font(textFont)
                .fontWeight(.bold)
                .monospacedDigit()
        }
        .padding(contentPadding)
        .frame(minHeight: minHeight)
        .backport
        .glassEffect(
            .regular.interactive(!viewLayout.isLarge),
            in: .capsule
        )
    }

    private var contentPadding: EdgeInsets {
        viewLayout.value(standard: EdgeInsets(vertical: 6, horizontal: 16), large: EdgeInsets(24))
    }

    private var iconSize: CGFloat {
        viewLayout.value(standard: 25, large: 30)
    }

    private var minHeight: CGFloat {
        viewLayout.value(standard: 40, large: 60)
    }

    private var textFont: Font {
        viewLayout.value(standard: .body, large: .subheadline)
    }

    private struct ToastButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.92 : 1)
                .animation(.interactiveSpring, value: configuration.isPressed)
        }
    }
}
