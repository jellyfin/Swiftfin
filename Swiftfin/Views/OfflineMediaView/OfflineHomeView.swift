//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Stinsen
import SwiftUI

struct OfflineHomeView: View {
    
    @EnvironmentObject
    var offlineHomeRouter: OfflineHomeCoordinator.Router
    @ObservedObject
    var viewModel: OfflineHomeViewModel
    
    @ViewBuilder
    private var itemList: some View {
        ScrollView {
            VStack {
                ForEach(viewModel.offlineItems, id: \.self) { offlineItem in
                    DownloadTrackerRow(offlineItem: offlineItem) { item in
                        offlineHomeRouter.route(to: \.item, item)
                    }
                }
            }
        }
    }
    
    var body: some View {
        Group {
            if viewModel.offlineItems.isEmpty {
                Text("No items")
            } else {
                itemList
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    offlineHomeRouter.route(to: \.settings)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .accessibilityLabel(L10n.settings)
                }
            }
        }
        .navigationBarTitle("Offline")
    }
}
