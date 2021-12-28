/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Defaults
import MessageUI
import Stinsen
import SwiftUI

// MARK: JellyfinPlayerApp
@main
struct JellyfinPlayerApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Default(.appAppearance) var appAppearance

    var body: some Scene {
        WindowGroup {
            MainCoordinator().view()
                .ignoresSafeArea()
                .onAppear {
                    setupAppearance()
                }
                .onOpenURL { url in
                    AppURLHandler.shared.processDeepLink(url: url)
                }
                .onChange(of: appAppearance) { newValue in
                    setupAppearance()
                }
        }
    }

    private func setupAppearance() {
        UIApplication.shared.windows.first?.overrideUserInterfaceStyle = appAppearance.style
    }
}

// MARK: Hosting Window
struct HostingWindowFinder: UIViewRepresentable {
    var callback: (UIWindow?) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async { [weak view] in
            callback(view?.window)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

extension View {
    func withHostingWindow(_ callback: @escaping (UIWindow?) -> Void) -> some View {
        background(HostingWindowFinder(callback: callback))
    }
}
