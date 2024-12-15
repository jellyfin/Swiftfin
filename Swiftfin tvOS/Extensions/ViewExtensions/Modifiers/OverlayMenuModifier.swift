//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct OverlayMenuModifier<Contents: View>: ViewModifier {

    // MARK: - Dialog State

    @Binding
    var isPresented: Bool

    // MARK: - Overlay Menu Contents

    let title: String?
    let subtitle: String?
    let contents: Contents

    // MARK: - Overlay Menu Actions

    let onSave: (() -> Void)?
    let onCancel: (() -> Void)?
    let onDismiss: (() -> Void)?

    // MARK: - Overlay Menu Actions

    let onDisappear: (() -> Void)?

    // MARK: - Include Footer

    private var includeFooter: Bool {
        onSave != nil || onCancel != nil || onDismiss != nil
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                ZStack {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)

                    menuView
                        .transition(.opacity)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: isPresented)
                        .onDisappear {
                            onDisappear?()
                        }
                }
            }
    }

    // MARK: - Menu View

    @ViewBuilder
    private var menuView: some View {
        VStack {
            menuTitleView

            ScrollView {
                contents
                    .frame(maxWidth: .infinity)
                    .padding(16)
            }

            if includeFooter {
                menuFooterView
                    .padding(16)
            }
        }
        .padding(32)
        .background {
            RoundedRectangle(cornerRadius: 50)
                .fill(Material.thin)
                .overlay(
                    RoundedRectangle(cornerRadius: 50)
                        .fill(Color.black.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 50)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .frame(
            minWidth: UIScreen.main.bounds.width / 4,
            maxWidth: UIScreen.main.bounds.width / 3,
            maxHeight: UIScreen.main.bounds.height / 1.5
        )
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Menu Title View

    private var menuTitleView: some View {
        VStack(spacing: 16) {
            if let title = title {
                Text(title)
                    .font(.subheadline)
                    .padding(.horizontal)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(16)
    }

    // MARK: - Menu Footer View

    private var menuFooterView: some View {
        HStack(spacing: 24) {
            /// Only Cancel OR Dismiss but not both. Prioritize Cancel over Dismiss.
            if let cancel = onCancel {
                footerButton(L10n.cancel, action: cancel)
            } else if let dismiss = onDismiss {
                footerButton(L10n.dismiss, action: dismiss)
            }

            /// Only show a Save button if there is an onSave action.
            if let save = onSave {
                footerButton(L10n.save, action: save)
            }
        }
    }

    // MARK: - Overlay Menu Footer Button(s)

    private func footerButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
            isPresented = false
        } label: {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)
        }
        .buttonStyle(.automatic)
    }
}
