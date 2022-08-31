//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FilterDrawerHStack: View {
    
    @EnvironmentObject
    private var router: LibraryCoordinator.Router
    
    @ObservedObject
    var viewModel: LibraryViewModel
    
    var body: some View {
        HStack {
            if viewModel.filters.hasFilters {
                Menu {
                    Text("Filters applied")
                    
                    Button(role: .destructive) {
                        print("reset")
                    } label: {
                        Text("Reset")
                    }
                } label: {
                    FilterDrawerButton(title: "a", activated: true)
                }
            }
            
            FilterDrawerButton(title: "Genres", activated: false)
                .onSelect {
                    router.route(to: \.filter)
                }
            
            FilterDrawerButton(title: "Tags", activated: false)
                .onSelect {
                    router.route(to: \.filter)
                }
        }
    }
}
