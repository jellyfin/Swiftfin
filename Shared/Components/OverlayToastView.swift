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

    @State
    private var safeAreaInsets = EdgeInsets()

    private var toastInsets: EdgeInsets {
        #if os(tvOS)
        EdgeInsets(top: 60, leading: 0, bottom: 0, trailing: 0)
        #else
        EdgeInsets(
            top: safeAreaInsets.top + 10,
            leading: safeAreaInsets.leading,
            bottom: 0,
            trailing: safeAreaInsets.trailing
        )
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
                        .padding(toastInsets)
                        .transition(.offset(y: -20).combined(with: .opacity))

                    Spacer()
                }
            }
        }
        #if os(iOS)
        .background {
                ToastSafeAreaReader {
                    safeAreaInsets = $0
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        #endif
            .animation(.easeInOut(duration: 0.2), value: toastProxy.isPresenting)
    }
}

#if os(iOS)
/// Reads the attached window's live safe area even when the toast host ignores it.
private struct ToastSafeAreaReader: UIViewRepresentable {

    let onChange: (EdgeInsets) -> Void

    func makeUIView(context: Context) -> Probe {
        let view = Probe()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: Probe, context: Context) {
        view.layoutDirection = context.environment.layoutDirection
        view.onChange = onChange
        view.reportInsets()
    }

    final class Probe: UIView {

        var layoutDirection: LayoutDirection = .leftToRight
        var onChange: ((EdgeInsets) -> Void)?

        private var lastInsets: EdgeInsets?

        override func layoutSubviews() {
            super.layoutSubviews()
            reportInsets()
        }

        override func safeAreaInsetsDidChange() {
            super.safeAreaInsetsDidChange()
            reportInsets()
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            lastInsets = nil
            reportInsets()
        }

        func reportInsets() {
            guard let window, bounds.width > 0, bounds.height > 0 else { return }

            let safeFrame = safeAreaLayoutGuide.layoutFrame
                .intersection(bounds)
                .intersection(convert(window.safeAreaLayoutGuide.layoutFrame, from: window))
            guard !safeFrame.isNull else { return }

            let left = max(0, safeFrame.minX - bounds.minX)
            let right = max(0, bounds.maxX - safeFrame.maxX)
            let insets = EdgeInsets(
                top: max(0, safeFrame.minY - bounds.minY),
                leading: layoutDirection == .leftToRight ? left : right,
                bottom: max(0, bounds.maxY - safeFrame.maxY),
                trailing: layoutDirection == .leftToRight ? right : left
            )
            guard lastInsets != insets else { return }

            lastInsets = insets

            DispatchQueue.main.async { [weak self] in
                guard let self, self.window != nil, self.lastInsets == insets else { return }

                self.onChange?(insets)
            }
        }
    }
}
#endif

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
        .backport
        .glassEffect(
            .regular.interactive(!UIDevice.isTV),
            in: .capsule
        )
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
