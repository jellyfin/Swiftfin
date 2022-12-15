//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import MessageUI
import Stinsen
import SwiftUI

@main
struct SwiftfinApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    init() {
        Task {
            for await newValue in Defaults.updates(.accentColor) {
                Self.setupAccentColor(with: newValue.uiColor)
                Self.setupNavigationBackButton(accentColor: newValue.uiColor)
            }
        }

        Task {
            for await newValue in Defaults.updates(.appAppearance) {
                Self.setupAppearance(with: newValue.style)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            PreferenceUIHostingControllerView {
                MainCoordinator()
                    .view()
                    .supportedOrientations(.portrait)
            }
            .ignoresSafeArea()
            .onOpenURL { url in
                AppURLHandler.shared.processDeepLink(url: url)
            }
        }
    }
    
    private static func setupAccentColor(with accentColor: UIColor) {
        UIApplication.shared.keyWindow?.tintColor = accentColor
    }

    private static func setupAppearance(with appearance: UIUserInterfaceStyle) {
        UIApplication.shared.keyWindow?.overrideUserInterfaceStyle = appearance
    }

    private static func setupNavigationBackButton(accentColor: UIColor) {
        let config = UIImage.SymbolConfiguration(paletteColors: [accentColor.overlayColor, accentColor])
        let backButtonBackgroundImage = UIImage(systemName: "chevron.backward.circle.fill", withConfiguration: config)
        let barAppearance = UINavigationBar.appearance()
        barAppearance.backIndicatorImage = backButtonBackgroundImage
        barAppearance.backIndicatorTransitionMaskImage = backButtonBackgroundImage
    }
}

extension UINavigationController {
    // Remove back button text
    override open func viewWillLayoutSubviews() {
        navigationBar.topItem?.backButtonDisplayMode = .minimal
    }
}
