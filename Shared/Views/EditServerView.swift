//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: change URL picker from menu to list with network-url mapping

/// - Note: Set the environment `isEditing` to `true` to
///         allow server deletion
struct EditServerView: View {

    @Router
    private var router

    @Environment(\.isEditing)
    private var isEditing

    @State
    private var currentServerURL: URL
    @State
    private var isPresentingConfirmDeletion: Bool = false

    @StateObject
    private var viewModel: ServerConnectionViewModel

    init(server: ServerState) {
        self._viewModel = StateObject(wrappedValue: ServerConnectionViewModel(server: server))
        self._currentServerURL = State(initialValue: server.currentURL)
    }

    var body: some View {
        Form(systemImage: "server.rack") {

            Section(L10n.server) {

                LabeledContent(
                    L10n.name,
                    value: viewModel.server.name
                )
                #if os(tvOS)
                .focusable(false)
                #endif

                if let serverVersion = StoredValues[.Server.publicInfo(id: viewModel.server.id)].version {
                    LabeledContent(
                        L10n.version,
                        value: serverVersion
                    )
                    #if os(tvOS)
                    .focusable(false)
                    #endif
                }
            }

            Section {
                #if os(tvOS)
                ListRowMenu(L10n.url, subtitle: currentServerURL.absoluteString) {
                    Picker(L10n.serverURL, selection: $currentServerURL) {
                        ForEach(viewModel.server.urls.sorted(using: \.absoluteString), id: \.self) { url in
                            Text(url.absoluteString)
                                .tag(url)
                        }
                    }
                }
                #else
                Picker(L10n.url, selection: $currentServerURL) {
                    ForEach(viewModel.server.urls.sorted(using: \.absoluteString), id: \.self) { url in
                        Text(url.absoluteString)
                            .tag(url)
                    }
                }
                #endif
            } header: {
                Text(L10n.serverURL)
            } footer: {
                if !viewModel.server.isVersionCompatible {
                    Label(
                        L10n.serverVersionWarning(viewModel.server.client.version.majorMinor.description),
                        systemImage: "exclamationmark.circle.fill"
                    )
                    .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }

            if isEditing {
                Section {
                    Button(L10n.delete, role: .destructive) {
                        isPresentingConfirmDeletion = true
                    }
                    .buttonStyle(.primary)
                }
            }
        }
        .navigationTitle(L10n.server)
        .backport
        .onChange(of: currentServerURL) { _, newValue in
            viewModel.setCurrentURL(to: newValue)
        }
        .alert(L10n.deleteServer, isPresented: $isPresentingConfirmDeletion) {
            Button(L10n.delete, role: .destructive) {
                viewModel.delete()
                router.dismiss()
            }
        } message: {
            Text(L10n.confirmDeleteServerAndUsers(viewModel.server.name))
        }
    }
}
