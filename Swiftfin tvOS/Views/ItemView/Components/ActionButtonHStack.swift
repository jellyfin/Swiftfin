//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {
    
    struct ActionButtonHStack: View {
        
        @ObservedObject
        var viewModel: ItemViewModel
        
        var body: some View {
            HStack {
                Button {
                    viewModel.toggleWatchState()
                } label: {
                    Image(systemName: "checkmark.circle")
                        .font(.title3)
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
//                        .frame(width: 100, height: 100)
                }
                .buttonStyle(PlainButtonStyle())
//                .buttonStyle(CardButtonStyle())
                
                Button {
                    viewModel.toggleFavoriteState()
                } label: {
                    Image(systemName: "heart")
                        .font(.title3)
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
//                        .frame(width: 100, height: 100)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}
