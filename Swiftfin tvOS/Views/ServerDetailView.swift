//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct EditServerView: View {

    @EnvironmentObject
    private var router: SelectUserCoordinator.Router

    @Environment(\.isEditing)
    private var isEditing

    @State
    private var isPresentingConfirmDeletion: Bool = false

    @StateObject
    private var viewModel: ServerConnectionViewModel

    init(server: ServerState) {
        self._viewModel = StateObject(wrappedValue: ServerConnectionViewModel(server: server))
    }

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(systemName: "server.rack")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {

                Section(L10n.server) {
                    TextPairView(
                        leading: L10n.name,
                        trailing: viewModel.server.name
                    )
                    .focusable(false)
                }

                Section(L10n.url) {
                    Menu {
                        ForEach(viewModel.server.urls.sorted(using: \.absoluteString), id: \.self) { url in
                            Button(action: {
                                guard viewModel.server.currentURL != url else { return }
                                viewModel.setCurrentURL(to: url)
                            }) {
                                HStack {
                                    Text(url.absoluteString)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    if viewModel.server.currentURL == url {
                                        Image(systemName: "checkmark")
                                            .font(.body.weight(.regular))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.server.currentURL.absoluteString)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if isEditing {
                    Section {
                        ListRowButton(L10n.delete) {
                            isPresentingConfirmDeletion = true
                        }
                        .foregroundStyle(.primary, .red.opacity(0.5))
                    }
                }
            }
            .withDescriptionTopPadding()
            .navigationTitle(L10n.server)
            .alert(L10n.deleteServer, isPresented: $isPresentingConfirmDeletion) {
                Button(L10n.delete, role: .destructive) {
                    viewModel.delete()
                    router.popLast()
                }
            } message: {
                Text("Are you sure you want to delete \(viewModel.server.name) and all of its connected users?")
            }
    }
}
