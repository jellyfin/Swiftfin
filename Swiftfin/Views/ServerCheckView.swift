//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

struct ServerCheckView: View {

    @EnvironmentObject
    private var router: MainCoordinator.Router

    @StateObject
    private var viewModel = ServerCheckViewModel()

    @ViewBuilder
    private func errorView<E: Error>(_ error: E) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(Color.red)

            Text(viewModel.userSession.server.name)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text(error.localizedDescription)
                .frame(minWidth: 50, maxWidth: 240)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private func loginInvalidatedView() -> some View {
        VStack(spacing: 10) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(Color.red)

            Text(viewModel.userSession.server.name)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text(
                "401: \(L10n.invalidatedLogin)"
            )
            .frame(minWidth: 50, maxWidth: 240)
            .multilineTextAlignment(.center)

            PrimaryButton(title: L10n.retry)
                .onSelect {
                    viewModel.send(.checkServer)
                }
                .frame(maxWidth: 300)
                .frame(height: 50)

            PrimaryButton(title: L10n.back, role: .destructive)
                .onSelect {
                    Defaults[.lastSignedInUserID] = .signedOut
                    Container.shared.currentUserSession.reset()
                    Notifications[.didSignOut].post()
                }
                .frame(maxWidth: 300)
                .frame(height: 50)
        }
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .initial, .connecting, .connected:
                ZStack {
                    Color.clear

                    ProgressView()
                }
            case let .error(error):
                errorView(error)
            case .loginInvalidated:
                loginInvalidatedView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .onFirstAppear {
            viewModel.send(.checkServer)
        }
        .onReceive(viewModel.$state) { newState in
            if newState == .connected {
                withAnimation(.linear(duration: 0.1)) {
                    let _ = router.root(\.mainTab)
                }
            }
        }
        .topBarTrailing {

            SettingsBarButton(
                server: viewModel.userSession.server,
                user: viewModel.userSession.user
            ) {
                router.route(to: \.settings)
            }
        }
    }
}
