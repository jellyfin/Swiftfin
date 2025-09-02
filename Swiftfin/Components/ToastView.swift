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

// TODO: make toasting system
//       - allow actions
//       - single injection function
//       - multiple toasts
//       - sizes, stacked
// TODO: be transparent

struct ToastView<Content: View>: View {

    @StateObject
    private var toastProxy: ToastProxy = .init()

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .window(
                level: .alert,
                transition: .move(edge: .top).combined(with: .opacity),
                isPresented: $toastProxy.isPresenting
            ) {
                _ToastView()
                    .environmentObject(toastProxy)
            }
            .environmentObject(toastProxy)
    }
}

@MainActor
class ToastProxy: ObservableObject {

    @Published
    var isPresenting: Bool = false
    @Published
    private(set) var systemName: String? = nil
    @Published
    private(set) var title: Text = Text("")
//    @Published
//    private(set) var messageID: String = ""

    private let pokeTimer = PokeIntervalTimer(defaultInterval: 1)
    private var pokeCancellable: AnyCancellable?

    init() {
        pokeCancellable = pokeTimer.hasFired
            .sink {
//                withAnimation {
//                    self.isPresenting = false
//                }
            }
    }

    func present(_ title: String, systemName: String? = nil) {
        present(Text(title), systemName: systemName)
    }

    func present(_ title: Text, systemName: String? = nil) {
        self.title = title
        self.systemName = systemName

        poke(equalsPrevious: title == self.title)
    }

    private func poke(equalsPrevious: Bool) {
//        if equalsPrevious {
//            messageID = UUID().uuidString
//        }

        withAnimation(.spring) {
            isPresenting = true
        }

        pokeTimer.poke()
    }
}

private struct _ToastView: View {

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
