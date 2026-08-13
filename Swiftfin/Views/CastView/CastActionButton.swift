//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import JellyfinAPI
import SwiftUI

struct CastActionButton<Label: View>: View {

    @Router
    private var router

    @StateObject
    private var viewModel: ActiveSessionsViewModel

    private let provider: MediaPlayerItemProvider
    private let label: (Bool) -> Label

    init(
        provider: MediaPlayerItemProvider,
        @ViewBuilder label: @escaping (Bool) -> Label
    ) {
        self.provider = provider
        self.label = label

        var environment = ActiveSessionsViewModel.Environment.default
        environment.userID = Container.shared.currentUserSession()?.user.id

        self._viewModel = StateObject(wrappedValue: ActiveSessionsViewModel(environment: environment))
    }

    private var isItemPlaying: Bool {
        viewModel.sessions.values.contains { target in
            CastMediaPlayerProxy.isPlaying(item: provider.item, in: target.session)
        }
    }

    var body: some View {
        Button {
            router.route(to: .castToJellyfin(provider: provider))
        } label: {
            label(isItemPlaying)
        }
    }
}
