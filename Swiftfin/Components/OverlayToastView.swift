//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import SwiftUI
import Transmission

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
        content
            .presentation(
                transition: .toast(
                    edge: .top,
                    isInteractive: true,
                    preferredPresentationBackgroundColor: .clear
                ),
                isPresented: $toastProxy.isPresenting
            ) {
                OverlayToastContent()
                    .environmentObject(toastProxy)
            }
            .environmentObject(toastProxy)
    }
}

private struct OverlayToastContent: View {

    @Environment(\.presentationCoordinator)
    private var presentationCoordinator

    @EnvironmentObject
    private var proxy: ToastProxy

    var body: some View {
        Button {
            presentationCoordinator.dismiss()
        } label: {
            HStack {
                if let systemName = proxy.systemName {
                    Image(systemName: systemName)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 25, height: 25)
                }

                proxy.title
                    .font(.body)
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .frame(minHeight: 50)
            .background(BlurView())
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.gray.opacity(0.2), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 6)
        }
        .buttonStyle(ToastButtonStyle())
    }

    struct ToastButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.92 : 1)
                .animation(.interactiveSpring, value: configuration.isPressed)
        }
    }
}
