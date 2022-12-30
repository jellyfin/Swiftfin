//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import JellyfinAPI

extension HomeView {
    struct HomeRecentlyAdded: View {
        @EnvironmentObject private var router: HomeCoordinator.Router
        @ObservedObject public var viewModel: ItemTypeLibraryViewModel
        
        @Binding var hasHero: Bool
        @Binding var heroVisible: Bool
        
        public let focusedImage: FocusState<String?>.Binding
        
        var body: some View {
            Group {
                if hasHero {
                    HomeSectionText(title: L10n.recentlyAdded, subtitle: "Recently added items from all libraries", callback: callback)
                        .frame(height: heroVisible && hasHero ? 0 : .infinity)
                        .animation(.easeInOut(duration: 0.25), value: heroVisible)
                        .opacity(heroVisible && hasHero ? 0 : 1)
                } else {
                    HomeSectionText(title: L10n.recentlyAdded, subtitle: "Recently added items from all libraries", visible: !heroVisible, callback: callback)
                }
                
                HomeItemRow(items: viewModel.items, size: .four, focusPrefix: "recentlyadded", focusedImage: focusedImage)
            }
        }
        
        private func callback() {
            router.route(to: \.basicLibrary, .init(title: L10n.recentlyAdded, viewModel: viewModel))
        }
    }
}
