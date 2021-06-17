//
 /*
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation
import SwiftUI

struct MainTabView: View {
    @State private var tabSelection: Tab = .home
    @StateObject private var viewModel = MainTabViewModel()
    @State private var backdropAnim: Bool = false
    @State private var lastBackdropAnim: Bool = false
    
    var body: some View {
        ZStack() {
            //please do not touch my magical crossfading.
            if(viewModel.backgroundURL != nil) {
                if(viewModel.lastBackgroundURL != nil) {
                    ImageView(src: viewModel.lastBackgroundURL!, bh: viewModel.backgroundBlurHash)
                        .frame(width: UIScreen.main.currentMode?.size.width, height: UIScreen.main.currentMode?.size.height)
                        .blur(radius: 2)
                        .opacity(lastBackdropAnim ? 0.4 : 0)
                        .onChange(of: viewModel.backgroundURL) { _ in
                            withAnimation(.linear(duration: 0.15)) {
                                lastBackdropAnim = false
                            }
                        }
                }
                ImageView(src: viewModel.backgroundURL!, bh: viewModel.backgroundBlurHash)
                    .frame(width: UIScreen.main.currentMode?.size.width, height: UIScreen.main.currentMode?.size.height)
                    .blur(radius: 2)
                    .opacity(backdropAnim ? 0.4 : 0)
                    .onChange(of: viewModel.backgroundURL) { _ in
                        lastBackdropAnim = true
                        backdropAnim = false
                        withAnimation(.linear(duration: 0.15)) {
                            backdropAnim = true
                        }
                    }
            }
            TabView(selection: $tabSelection) {
                HomeView()
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Text(Tab.home.localized)
                    Image(systemName: "house")
                }
                .tag(Tab.home)
                
                Text("Library")
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Text(Tab.allMedia.localized)
                    Image(systemName: "folder")
                }
                .tag(Tab.allMedia)
            }
        }
    }
}

extension MainTabView {
    enum Tab: String {
        case home
        case allMedia
        
        var localized: String {
            switch self {
            case .home:
                return "Home"
            case .allMedia:
                return "All Media"
            }
        }
    }
}
