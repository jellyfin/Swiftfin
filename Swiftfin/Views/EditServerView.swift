//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

// TODO: change URL picker from menu to list with network-url mapping

/// - Note: Set the environment `isEditing` to `true` to
///         allow server deletion
struct EditServerView: View {

    @EnvironmentObject
    private var router: SelectUserCoordinator.Router

    @Environment(\.isEditing)
    private var isEditing

    @State
    private var currentServerURL: URL
    @State
    private var isPresentingConfirmDeletion: Bool = false

    @StateObject
    private var viewModel: ServerConnectionViewModel

    // TODO: Figure out CoreStore and just hold onto the server version
    @State
    private var isVersionCompatible: Bool = false

    init(server: ServerState) {
        self._viewModel = StateObject(wrappedValue: ServerConnectionViewModel(server: server))
        self._currentServerURL = State(initialValue: server.currentURL)
    }

    var body: some View {
        List {
            Section {

                TextPairView(
                    leading: L10n.name,
                    trailing: viewModel.server.name
                )

                // TODO: Figure out CoreStore and just hold onto the server version
                /*TextPairView(
                    leading: L10n.version,
                    trailing: viewModel.server.version
                )*/

                Picker(L10n.url, selection: $currentServerURL) {
                    ForEach(viewModel.server.urls.sorted(using: \.absoluteString), id: \.self) { url in
                        Text(url.absoluteString)
                            .tag(url)
                            .foregroundColor(.secondary)
                    }
                }
            } footer: {
                if isVersionCompatible {
                // if viewModel.userSession.server.isVersionCompatible() {
                    Label(
                        "Server version does not meet the minimum requirement (\(JellyfinClient.sdkVersion.majorMinor.description)) for Swiftfin",
                        systemImage: "exclamationmark.circle.fill"
                    )
                    .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }

            if isEditing {
                ListRowButton(L10n.delete) {
                    isPresentingConfirmDeletion = true
                }
                .foregroundStyle(.red, .red.opacity(0.2))
            }
        }
        .navigationTitle(L10n.server)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: currentServerURL) { newValue in
            viewModel.setCurrentURL(to: newValue)
        }
        .alert(L10n.deleteServer, isPresented: $isPresentingConfirmDeletion) {
            Button(L10n.delete, role: .destructive) {
                viewModel.delete()
                router.popLast()
            }
        } message: {
            Text(L10n.confirmDeleteServerAndUsers(viewModel.server.name))
        }
        // TODO: Remove when CoreStore has a ServerVersion
        .onFirstAppear {
            Task {
                do {
                    isVersionCompatible = try await viewModel.userSession.server.isVersionCompatible()
                } catch {
                    isVersionCompatible = false
                }
            }
        }
    }
}
