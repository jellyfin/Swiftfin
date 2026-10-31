//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import SwiftUI
import WebKit

struct JellyfinWebView: View {

    @Injected(\.currentUserSession)
    private var userSession

    @Router
    private var router

    let path: String
    let queryItems: [URLQueryItem]

    private var url: URL? {
        guard let serverURL = userSession?.client.configuration.url,
              var components = URLComponents(url: serverURL, resolvingAgainstBaseURL: false)
        else { return nil }

        var route = URLComponents()
        route.path = "/" + path
        route.queryItems = queryItems.isEmpty ? nil : queryItems

        // The server redirects its root to wherever it hosts the web client.
        // - This is needed to handle / vs /web vs custom redirections.
        components.path = components.path.trimmingSuffix("/") + "/"
        components.percentEncodedFragment = route.string

        return components.url
    }

    var body: some View {
        ZStack {
            if let userSession, let url {
                JellyfinWebUIView(
                    userSession: userSession,
                    url: url
                )
                .ignoresSafeArea(edges: .bottom)
            } else {
                ErrorView(error: ErrorMessage(L10n.unknownError))
            }
        }
        .navigationTitle(userSession?.server.name ?? L10n.jellyfin)
        .toolbarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            if let url {
                Button(L10n.openInSafari, systemImage: "safari") {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
}

private struct JellyfinWebUIView: UIViewRepresentable {

    let userSession: UserSession
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.defaultWebpagePreferences.preferredContentMode = .mobile

        // Provide Jellyfin-Web our session information only on the server's origin.
        let serverURL = userSession.client.configuration.url
        let session: [String: Any] = [
            "serverURL": serverURL.absoluteString,
            "deviceID": userSession.client.configuration.deviceID,
            "credentials": [
                "Servers": [
                    [
                        "Id": userSession.server.id,
                        "Name": userSession.server.name,
                        "ManualAddress": serverURL.absoluteString.trimmingSuffix("/"),
                        "LastConnectionMode": 2,
                        "UserId": userSession.user.id,
                        "AccessToken": userSession.client.accessToken ?? "",
                        "DateLastAccessed": Int(Date.now.timeIntervalSince1970 * 1000),
                    ],
                ],
            ],
        ]

        if let sessionData = try? JSONSerialization.data(withJSONObject: session),
           let sessionJSON = String(data: sessionData, encoding: .utf8)
        {
            configuration.userContentController.addUserScript(
                WKUserScript(
                    source: """
                    (() => {
                        const session = \(sessionJSON);
                        if (window.location.origin !== new URL(session.serverURL).origin) {
                            return;
                        }

                        localStorage.setItem('jellyfin_credentials', JSON.stringify(session.credentials));
                        localStorage.setItem('_deviceId2', session.deviceID);
                        localStorage.setItem('layout', 'mobile');
                    })();
                    """,
                    injectionTime: .atDocumentStart,
                    forMainFrameOnly: true
                )
            )
        }

        /// `.zero` then resizes to fill container
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.load(URLRequest(url: url))

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}
