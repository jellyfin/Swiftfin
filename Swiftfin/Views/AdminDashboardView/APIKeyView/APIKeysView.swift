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

    // MARK: - Alerts & Confirmations

    @State
    private var showCopiedAlert = false
    @State
    private var showReplaceConfirmation = false
    @State
    private var showCreateAPIAlert = false
    @State
    private var showDeleteConfirmation = false

    // MARK: - New API Variables

    @State
    private var newAPIName: String = ""

    // MARK: - Update API Variables

    @State
    private var deleteAPI: AuthenticationInfo?
    @State
    private var replaceAPI: AuthenticationInfo?

    // MARK: - State Objects

    @StateObject
    private var viewModel = APIKeysViewModel()

    // MARK: - Error View

    @ViewBuilder
    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.refresh()
            }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .error:
                viewModel.error.map { errorView(with: $0) }
            case .initial, .updating:
                contentView
            case .refreshing:
                DelayedProgressView()
            }
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .animation(.linear(duration: 0.1), value: viewModel.apiKeys)
        .navigationTitle(L10n.apiKeys)
        .onFirstAppear {
            viewModel.refresh()
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
                    viewModel.delete(key: key)
                }
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.deleteItemConfirmation)
        }
        .confirmationDialog(
            L10n.replace,
            isPresented: $showReplaceConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.replace, role: .destructive) {
                if let key = replaceAPI?.accessToken {
                    viewModel.update(key: key)
                }
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.replaceItemConfirmation)
        }
        .alert(L10n.createAPIKey, isPresented: $showCreateAPIAlert) {
            TextField(L10n.applicationName, text: $newAPIName)
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.save) {
                viewModel.create(name: newAPIName)
                newAPIName = ""
            }
        } message: {
            Text(L10n.createAPIKeyMessage)
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated:
                UIDevice.feedback(.success)
            }
        }
        .errorMessage($viewModel.error)
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
                    } onReplace: {
                        replaceAPI = apiKey
                        showReplaceConfirmation = true
                    }
                }
            } else {
                Button(L10n.add) {
                    showCreateAPIAlert = true
                }
                .foregroundStyle(Color.accentColor)
            }
        }
    }
}
