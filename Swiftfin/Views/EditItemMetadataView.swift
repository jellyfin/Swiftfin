//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CollectionView
import JellyfinAPILegacy
import SwiftUI

struct EditItemMetadataView: View {
    
    @ObservedObject
    var viewModel: RemoteImageViewModel
    
    var body: some View {
        CollectionView(items: viewModel.images) { _, imageInfo, _ in
            ImageView(URL(string: imageInfo.url ?? ""))
                .frame(width: 100, height: 150)
        }
    }
}
