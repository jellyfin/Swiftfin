//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct APIKeysView: View {

    @Router
    private var router

    @State
    private var appName: String = ""
    @State
    private var showCreateAPIAlert = false

    @StateObject
    private var viewModel = APIKeysViewModel()

    private var contentView: some View {
        List {
            ListTitleSection(
                L10n.apiKeysCapitalized,
                description: L10n.apiKeysDescription
            )

            if viewModel.apiKeys.isNotEmpty {
                ForEach(viewModel.apiKeys, id: \.accessToken) { apiKey in
                    APIKeysRow(
                        apiKey: apiKey
                    ) {
                        viewModel.delete(key: apiKey)
                    } replaceAction: {
                        viewModel.replace(key: apiKey)
                    }
                }
            } else {
                Button(L10n.add) {
                    showCreateAPIAlert = true
                }
            }
        }
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .error:
                viewModel.error.map {
                    ErrorView(error: $0)
                }
            case .initial:
                contentView
            case .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .animation(.linear(duration: 0.1), value: viewModel.apiKeys)
        .navigationTitle(L10n.apiKeysCapitalized)
        .refreshable {
            viewModel.refresh()
        }
        .onFirstAppear {
            viewModel.refresh()
        }
        .topBarTrailing {

            if viewModel.background.is(.updating) {
                ProgressView()
            }

            if viewModel.apiKeys.isNotEmpty {
                Button(L10n.add) {
                    showCreateAPIAlert = true
                    UIDevice.impact(.light)
                }
                .buttonStyle(.toolbarPill)
            }
        }
        .alert(
            L10n.createAPIKeyCapitalized,
            isPresented: $showCreateAPIAlert
        ) {
            TextField(L10n.applicationName, text: $appName)
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.save) {
                viewModel.create(name: appName)
                appName = ""
            }
        } message: {
            Text(L10n.createAPIKeyMessage)
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .createdKey:
                UIDevice.feedback(.success)
            }
        }
        .errorMessage($viewModel.error)
    }
}
