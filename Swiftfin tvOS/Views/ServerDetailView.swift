//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct EditServerView: View {

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
                Section(L10n.serverDetails) {

                    TextPairView(
                        leading: L10n.name,
                        trailing: viewModel.server.name
                    )

//                    TextPairView(
//                        leading: L10n.url,
//                        trailing: viewModel.server.currentURL.absoluteString
//                    )
                }
            }
            .withDescriptionTopPadding()
            .navigationTitle(L10n.server)
    }
}
