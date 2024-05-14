//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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
    private var viewModel: EditServerViewModel

    init(server: ServerState) {
        self._viewModel = StateObject(wrappedValue: EditServerViewModel(server: server))
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
                }

                Section("URL") {
                    ForEach(viewModel.server.urls.sorted(using: \.absoluteString)) { url in
                        if url == viewModel.server.currentURL {
                            Button(url.absoluteString, systemImage: "checkmark") {}
                        } else {
                            Button(url.absoluteString) {
                                viewModel.setCurrentURL(to: url)
                            }
                        }
                    }
                }

                if isEditing {
                    ListRowButton("Delete") {
                        isPresentingConfirmDeletion = true
                    }
                    .foregroundStyle(.primary, .red.opacity(0.5))
                }
            }
            .withDescriptionTopPadding()
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
