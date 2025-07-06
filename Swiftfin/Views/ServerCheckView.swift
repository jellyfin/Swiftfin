//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import SwiftUI

struct ServerCheckView: View {

    @EnvironmentObject
    private var rootCoordinator: RootCoordinator

    @Router
    private var router

    @StateObject
    private var viewModel = ServerCheckViewModel()

    @Injected(\.networkMonitor)
    private var networkMonitor

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

            PrimaryButton(title: L10n.retry)
                .onSelect {
                    viewModel.send(.checkServer)
                }
                .frame(maxWidth: 300)
                .frame(height: 50)

            if !networkMonitor.isConnected {
                Button {
                    rootCoordinator.root(.downloads)
                } label: {
                    Label("View Downloads", systemImage: "arrow.down.circle")
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: 300)
            }
        }
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .initial, .connecting, .connected, .serverUnreachable:
                ZStack {
                    Color.clear

                    ProgressView()
                }
            case let .error(error):
                errorView(error)
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .onFirstAppear {
            viewModel.send(.checkServer)
        }
        .onReceive(viewModel.$state) { newState in
            if newState == .connected {
                rootCoordinator.root(.mainTab)
            }
        }
        .topBarTrailing {

            SettingsBarButton(
                server: viewModel.userSession.server,
                user: viewModel.userSession.user
            ) {
                router.route(to: .settings)
            }
        }
    }
}
