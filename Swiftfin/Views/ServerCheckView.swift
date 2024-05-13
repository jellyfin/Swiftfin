//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ServerCheckView: View {

    @EnvironmentObject
    private var router: MainCoordinator.Router

    @StateObject
    private var viewModel = ServerCheckViewModel()

    var body: some View {
        WrappedView {
            switch viewModel.state {
            case .initial, .connecting, .connected:
                ProgressView()
            case let .error(error):
                ErrorView(error: error)
                    .onRetry {
                        viewModel.send(.checkServer)
                    }
            }
        }
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
