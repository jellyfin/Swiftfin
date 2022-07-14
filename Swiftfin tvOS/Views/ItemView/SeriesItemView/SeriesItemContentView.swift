//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import SwiftUI

extension SeriesItemView {
    
    enum FocusTransition: Hashable {
        case leavingActionBottom
        case leavingSeasonsTop
        case leavingSeasonsBottom
    }
    
    struct ContentView: View {
        
        @Default(.showPosterLabels)
        var showPosterLabels
        @EnvironmentObject
        private var itemRouter: ItemCoordinator.Router
        @ObservedObject
        var viewModel: SeriesItemViewModel
        @State
        var scrollViewProxy: ScrollViewProxy
        @State
        var showLogo: Bool = false
        
        // MARK: Transition
        
        @State
        var transitionBinding: FocusTransition?
        
        var body: some View {
            VStack(spacing: 0) {
                
                ItemView.StaticOverlayView(viewModel: viewModel,
                                           scrollViewProxy: scrollViewProxy,
                                           seriesItemTransitionBinding: $transitionBinding)
                .frame(height: UIScreen.main.bounds.height - 150)
                .padding(.bottom, 50)
                .id("staticOverlayView")
                
                VStack(spacing: 0) {
                    
                    Color.red
                        .frame(height: 0.5)
                        .id("topContentDivider")

                    if showLogo {
                        ImageView(viewModel.item.getLogoImage(maxWidth: 500),
                                  resizingMode: .aspectFit,
                                  failureView: {
                                      Text(viewModel.item.displayName)
                                          .font(.largeTitle)
                                          .fontWeight(.semibold)
                                          .lineLimit(2)
                                          .multilineTextAlignment(.leading)
                                          .foregroundColor(.white)
                                  })
                                .frame(width: 500, height: 150)
                                .padding(.top, 5)
                    }
                    
                    SeriesEpisodesView(viewModel: viewModel,
                                      seriesItemTransitionBinding: $transitionBinding)
                        .focusSection()
                        .id("seasonsAndEpisodes")
                    
                    PortraitImageHStack(title: L10n.recommended,
                                        items: viewModel.similarItems) { item in
                        print("here")
                    }
                                        .id("recommendedItems")
                    
//                    if !viewModel.similarItems.isEmpty {
//                        PortraitImageHStack(rowTitle: L10n.recommended,
//                                             items: viewModel.similarItems,
//                                             showItemTitles: showPosterLabels) { item in
//                            itemRouter.route(to: \.item, item)
//                        }
//                    }
                    
                    Spacer()
                }
                .frame(minHeight: UIScreen.main.bounds.height)
//                    .focusSection()
            }
            .background {
                BlurView()
                    .mask {
                        VStack(spacing: 0) {
                            LinearGradient(gradient: Gradient(stops: [
                                .init(color: .white, location: 0),
                                .init(color: .white.opacity(0.5), location: 0.2),
                                .init(color: .white.opacity(0), location: 1),
                            ]), startPoint: .bottom, endPoint: .top)
                            .frame(height: UIScreen.main.bounds.height - 150)
                            
                            Color.white
                        }
                    }
            }
            .onChange(of: transitionBinding) { newValue in
                if newValue == .leavingActionBottom {
                    withAnimation {
                        self.showLogo = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation {
                            scrollViewProxy.scrollTo("topContentDivider")
                        }
                    }
                } else if newValue == .leavingSeasonsTop {
                    withAnimation {
                        self.showLogo = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation {
                            scrollViewProxy.scrollTo("staticOverlayView")
                        }
                    }
                }
            }
        }
    }
}
