//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import JellyfinAPI
import SwiftUI

struct APIKeyView: View {

    // MARK: - Router

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    // MARK: - View Model

    @StateObject
    private var viewModel: APIKeyViewModel

    // MARK: - State Variables

    @State
    private var showCopiedAlert = false
    @State
    private var showDeleteConfirmation = false
    @State
    private var showCreateAPIAlert = false
    @State
    private var newAPIName: String = ""
    @State
    private var apiKeyToDelete: String?

    // MARK: - Initializer

    init() {
        self._viewModel = .init(wrappedValue: APIKeyViewModel())
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                if viewModel.apiKeys.isEmpty {
                    Text(L10n.none)
                } else {
                    apiKeyListView
                }
            case let .error(error):
                ErrorView(error: error)
                    .onRetry {
                        viewModel.send(.getAPIKeys)
                    }
            case .initial:
                DelayedProgressView()
            }
        }
        .navigationTitle(L10n.apiKeys)
        .onFirstAppear {
            viewModel.send(.getAPIKeys)
        }
        .topBarTrailing {
            Button(L10n.add) {
                showCreateAPIAlert = true
                UIDevice.impact(.light)
            }
            .buttonStyle(.toolbarPill)
        }
        .alert(L10n.apiKeyCopied, isPresented: $showCopiedAlert) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            Text(L10n.apiKeyCopiedMessage)
        }
        .confirmationDialog(
            L10n.deleteAPIKey,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.delete, role: .destructive) {
                if let key = apiKeyToDelete {
                    viewModel.send(.deleteAPIKey(key: key))
                }
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.confirmDeleteAPIKeyMessage)
        }
        .alert(L10n.createAPIKey, isPresented: $showCreateAPIAlert) {
            TextField(L10n.applicationName, text: $newAPIName)
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.save) {
                viewModel.send(.createAPIKey(name: newAPIName))
            }
        } message: {
            Text(L10n.createAPIKeyMessage)
        }
    }

    // MARK: - API Key List View

    private var apiKeyListView: some View {
        /* ListTitleSection(
             L10n.apiKeysTitle,
             description: L10n.apiKeysDescription
         ) */
        CollectionVGrid(
            viewModel.apiKeys.keys,
            layout: .columns(1, insets: .zero, itemSpacing: 8, lineSpacing: 8)
        ) { key in
            APIKeyRow(box: viewModel.apiKeys[key]!) {
                UIPasteboard.general.string = viewModel.apiKeys[key]!.value?.accessToken
                showCopiedAlert = true
            } onDelete: {
                apiKeyToDelete = viewModel.apiKeys[key]!.value?.accessToken
                showDeleteConfirmation = true
            }
        }
    }
}
