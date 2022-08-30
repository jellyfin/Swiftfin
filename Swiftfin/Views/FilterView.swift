//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FilterView: View {
    
    @EnvironmentObject
    private var router: FilterCoordinator.Router
    
    var body: some View {
        
        Text("Hello there")
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        router.dismissCoordinator()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
            }
        
//        MultiSelector(
//            label: L10n.genres,
//            options: ,
//            optionToString: { $0.name ?? "" },
//            selected: $viewModel.modifiedFilters.genres
//        )
    }
}
