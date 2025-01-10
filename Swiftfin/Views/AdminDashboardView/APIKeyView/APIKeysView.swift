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

    @EnvironmentObject
    private var router: AdminDashboardCoordinator.Router

    @State
    private var showCopiedAlert = false
    @State
    private var showDeleteConfirmation = false
    @State
    private var showCreateAPIAlert = false
    @State
    private var newAPIName: String = ""
    @State
    private var deleteAPI: AuthenticationInfo?

    @StateObject
    private var viewModel = APIKeysViewModel()

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                contentView
            case let .error(error):
                ErrorView(error: error)
                    .onRetry {
                        viewModel.send(.getAPIKeys)
                    }
            case .initial:
                DelayedProgressView()
            }
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .animation(.linear(duration: 0.1), value: viewModel.apiKeys)
        .navigationTitle(L10n.apiKeys)
        .onFirstAppear {
            viewModel.send(.getAPIKeys)
        }
        .topBarTrailing {
            if viewModel.apiKeys.isNotEmpty {
                Button(L10n.add) {
                    showCreateAPIAlert = true
                    UIDevice.impact(.light)
                }
                .buttonStyle(.toolbarPill)
            }
        }
        .alert(L10n.apiKeyCopied, isPresented: $showCopiedAlert) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            Text(L10n.apiKeyCopiedMessage)
        }
        .confirmationDialog(
            L10n.delete,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.delete, role: .destructive) {
                if let key = deleteAPI?.accessToken {
                    viewModel.send(.deleteAPIKey(key: key))
                }
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.deleteAPIKeyMessage)
        }
        .alert(L10n.createAPIKey, isPresented: $showCreateAPIAlert) {
            TextField(L10n.applicationName, text: $newAPIName)
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.save) {
                viewModel.send(.createAPIKey(name: newAPIName))
                newAPIName = ""
            }
        } message: {
            Text(L10n.createAPIKeyMessage)
        }
    }

    // MARK: - API Key Content

    private var contentView: some View {
        List {
            ListTitleSection(
                L10n.apiKeysTitle,
                description: L10n.apiKeysDescription
            )

            if viewModel.apiKeys.isNotEmpty {
                ForEach(viewModel.apiKeys, id: \.accessToken) { apiKey in
                    APIKeysRow(apiKey: apiKey) {
                        UIPasteboard.general.string = apiKey.accessToken
                        showCopiedAlert = true
                    } onDelete: {
                        deleteAPI = apiKey
                        showDeleteConfirmation = true
                    }
                }
            } else {
                Button(L10n.addAPIKey) {
                    showCreateAPIAlert = true
                }
                .foregroundStyle(Color.accentColor)
            }
        }
    }
}
