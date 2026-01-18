//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// A basic toasting container view that will present
/// given toasts on top of the given content.
struct OverlayToastView<Content: View>: View {

    @StateObject
    private var toastProxy: ToastProxy

    private let content: Content

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
                        .padding(.top, 60)
                        .transition(.move(edge: .top).combined(with: .opacity))

                    Spacer()
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toastProxy.isPresenting)
    }
}

private struct OverlayToastContent: View {

    @EnvironmentObject
    private var proxy: ToastProxy

    var body: some View {
        HStack {
            if let systemName = proxy.systemName {
                Image(systemName: systemName)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
            }

            proxy.title
                .font(.subheadline)
                .fontWeight(.bold)
                .monospacedDigit()
        }
        .padding(24)
        .frame(minHeight: 60)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.gray.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}
