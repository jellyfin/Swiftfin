//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ServerCheckView: View {

    @EnvironmentObject
    private var rootCoordinator: RootCoordinator

    @Router
    private var router

    @StateObject
    private var viewModel = ServerCheckViewModel()

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .initial:
                ZStack {
                    Color.clear

                    ProgressView()
                }
            case .error:
                viewModel.error.map {
                    ErrorView(error: $0)
                }
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .refreshable {
            viewModel.checkServer()
        }
        .onFirstAppear {
            viewModel.checkServer()
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .connected:
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
