//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

struct HomeView: View {

    @EnvironmentObject
    private var router: HomeCoordinator.Router

    @ObservedObject
    var viewModel: HomeViewModel

    var body: some View {
        Group {
            if let errorMessage = viewModel.errorMessage {
                ErrorView(
                    viewModel: viewModel,
                    errorMessage: .init(message: errorMessage, code: -1)
                )
            } else if viewModel.isLoading {
                ProgressView()
            } else {
                ContentView(viewModel: viewModel)
            }
        }
        .navigationTitle(L10n.home)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    router.route(to: \.settings)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .accessibilityLabel(L10n.settings)
                }
            }
        }
    }
}
