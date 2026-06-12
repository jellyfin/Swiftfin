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

    @StateObject
    private var toastProxy: ToastProxy

    private let content: Content

    @Environment(\.safeAreaInsets)
    private var safeAreaInsets

    private var topPadding: CGFloat {
        #if os(tvOS)
        60
        #else
        safeAreaInsets.top + 10
        #endif
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

private struct OverlayToastContent: View {

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
        .background(.thinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.gray.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 5)
    }

    private var contentPadding: EdgeInsets {
        #if os(tvOS)
        EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24)
        #else
        EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
        #endif
    }

    private var iconSize: CGFloat {
        #if os(tvOS)
        30
        #else
        25
        #endif
    }

    private var minHeight: CGFloat {
        #if os(tvOS)
        60
        #else
        40
        #endif
    }

    private var textFont: Font {
        #if os(tvOS)
        .subheadline
        #else
        .body
        #endif
    }

    private struct ToastButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.92 : 1)
                .animation(.interactiveSpring, value: configuration.isPressed)
        }
    }
}
