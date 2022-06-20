//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {
    
    struct DotHStack: View {
        
        @EnvironmentObject
        private var viewModel: ItemViewModel
        
        var body: some View {
            HStack {

                if let firstGenre = viewModel.item.genres?.first {
                    Text(firstGenre)

                    Circle()
                        .frame(width: 2, height: 2)
                        .padding(.horizontal, 1)
                }

                if let premiereYear = viewModel.item.premiereDateYear {
                    Text(String(premiereYear))

                    Circle()
                        .frame(width: 2, height: 2)
                        .padding(.horizontal, 1)
                }

                if let playButtonitem = viewModel.playButtonItem, let runtime = playButtonitem.getItemRuntime() {
                    Text(runtime)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal)
        }
    }
}
