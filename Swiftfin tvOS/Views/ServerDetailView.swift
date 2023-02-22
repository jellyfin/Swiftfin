//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ServerDetailView: View {

    @ObservedObject
    var viewModel: ServerDetailViewModel

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(systemName: "server.rack")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {
                Section(header: L10n.serverDetails.text) {
                    
                    TextPairView(
                        leading: L10n.name,
                        trailing: viewModel.userSession.server.name
                    )
                    
                    TextPairView(
                        leading: L10n.url,
                        trailing: viewModel.userSession.server.currentURL.absoluteString
                    )
                    
                    TextPairView(
                        leading: L10n.version,
                        trailing: viewModel.userSession.server.version
                    )
                    
                    TextPairView(
                        leading: L10n.operatingSystem,
                        trailing: viewModel.userSession.server.os
                    )
                }
            }
            .withDescriptionTopPadding()
            .navigationTitle(L10n.server)
    }
}
