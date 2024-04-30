//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Factory
import SwiftUI

#warning("TODO: break into 2 views for userlist and basic user")

struct ServerDetailView: View {

    @EnvironmentObject
    private var router: UserListCoordinator.Router

    @Environment(\.isEnabled)
    private var isEnabled

    @State
    private var currentServerURL: URL
    @State
    private var isPresentingConfirmDeletion: Bool = false

    @StateObject
    private var viewModel: ServerDetailViewModel

    init(server: ServerState) {
        self._viewModel = StateObject(wrappedValue: ServerDetailViewModel(server: server))
        self._currentServerURL = State(initialValue: server.currentURL)
    }

    var body: some View {
        List {
            Section {

                TextPairView(
                    leading: L10n.name,
                    trailing: viewModel.server.name
                )

                Picker(L10n.url, selection: $currentServerURL) {
                    ForEach(viewModel.server.urls.sorted(using: \.absoluteString)) { url in
                        Text(url.absoluteString)
                            .tag(url)
                            .foregroundColor(.secondary)
                    }
                    .onChange(of: currentServerURL) { newValue in
                        viewModel.setCurrentServerURL(to: newValue)
                    }
                }
            }

            if isEnabled {
                Button("Delete", systemImage: "trash.fill", role: .destructive) {
                    isPresentingConfirmDeletion = true
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
                .listRowBackground(Color.red.opacity(0.1))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(L10n.server)
        .alert("Delete Server", isPresented: $isPresentingConfirmDeletion) {
            Button("Delete", role: .destructive) {
                viewModel.delete()
                router.popLast()
            }
        } message: {
            Text("Are you sure you want to delete \(viewModel.server.name) and all of its connected users?")
        }
    }
}
