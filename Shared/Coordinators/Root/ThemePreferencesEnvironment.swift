//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import FactoryKit
import SwiftUI

struct ThemePreferencesEnvironment<Content: View>: View {

    @InjectedObject(\.userSessionManager)
    private var userSessionManager

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .modifier(StoredThemePreferencesModifier(userID: userSessionManager.currentSession?.user.id))
    }
}

private struct StoredThemePreferencesModifier: ViewModifier {

    #if os(iOS)
    @Default(.appAppearance)
    private var appAppearance
    @Default(.selectUserUseSplashscreen)
    private var useSplashscreen
    @Default
    private var userAppearance: AppAppearance
    #endif

    @Default
    private var userAccentColor: Color

    let userID: String?

    init(userID: String?) {
        self.userID = userID
        #if os(iOS)
        _userAppearance = Default(.userAppearance(userID: userID ?? "default"))
        #endif
        _userAccentColor = Default(.userAccentColor(userID: userID ?? "default"))
    }

    private var theme: AppTheme.Value {
        #if os(tvOS)
        AppTheme.Value(appearance: .dark, accentColor: userID == nil ? .jellyfinPurple : userAccentColor)
        #else
        if userID != nil {
            AppTheme.Value(appearance: userAppearance, accentColor: userAccentColor)
        } else {
            AppTheme.Value(appearance: useSplashscreen ? .dark : appAppearance)
        }
        #endif
    }

    func body(content: Content) -> some View {
        content
            .background {
                ThemeWindowBridge()
            }
            .environment(\.theme, theme)
            .transformEnvironment(\.colorScheme) { colorScheme in
                switch theme.appearance {
                case .system:
                    break
                case .dark:
                    colorScheme = .dark
                case .light:
                    colorScheme = .light
                }
            }
    }
}

private struct ThemeWindowBridge: UIViewRepresentable {

    @AppTheme
    private var theme

    func makeUIView(context: Context) -> ThemeView {
        let view = ThemeView()
        view.isUserInteractionEnabled = false
        view.theme = theme
        return view
    }

    func updateUIView(_ uiView: ThemeView, context: Context) {
        uiView.theme = theme
    }

    final class ThemeView: UIView {

        var theme = AppTheme.Value() {
            didSet { applyTheme() }
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            applyTheme()
        }

        private func applyTheme() {
            guard let window else { return }

            if window.overrideUserInterfaceStyle != theme.appearance.style {
                window.overrideUserInterfaceStyle = theme.appearance.style
            }

            let accentColor = UIColor(theme.accentColor)

            if window.tintColor != accentColor {
                window.tintColor = accentColor
            }
        }
    }
}
