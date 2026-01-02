//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct EditServerView: View {

    @Router
    private var router

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
                    LabeledContent(
                        L10n.name,
                        value: viewModel.server.name
                    )
                    .focusable(false)

                    if let serverVerion = StoredValues[.Server.publicInfo(id: viewModel.server.id)].version {
                        LabeledContent(
                            L10n.version,
                            value: serverVerion
                        )
                        .focusable(false)
                    }
                }

                Section {
                    ListRowMenu(L10n.serverURL, subtitle: viewModel.server.currentURL.absoluteString) {
                        ForEach(viewModel.server.urls.sorted(using: \.absoluteString), id: \.self) { url in
                            Button {
                                guard viewModel.server.currentURL != url else { return }
                                viewModel.setCurrentURL(to: url)
                            } label: {
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
                    }
                } header: {
                    Text(L10n.url)
                } footer: {
                    if !viewModel.server.isVersionCompatible {
                        Label(
                            L10n.serverVersionWarning(JellyfinClient.sdkVersion.majorMinor.description),
                            systemImage: "exclamationmark.circle.fill"
                        )
                    }
                }

                if isEditing {
                    Section {
                        Button(L10n.delete, role: .destructive) {
                            isPresentingConfirmDeletion = true
                        }
                        .buttonStyle(.primary)
                        .listRowBackground(Color.clear)
                        .listRowInsets(.zero)
                    }
                }
            }
            .navigationTitle(L10n.server)
            .alert(L10n.deleteServer, isPresented: $isPresentingConfirmDeletion) {
                Button(L10n.delete, role: .destructive) {
                    viewModel.delete()
//                    router.popLast()
                }
            } message: {
                Text(L10n.confirmDeleteServerAndUsers(viewModel.server.name))
            }
    }
}
