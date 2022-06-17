//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension MovieItemView {
    
    struct CompactLogoScrollView: View {
        
        @EnvironmentObject
        var itemRouter: ItemCoordinator.Router
        @EnvironmentObject
        private var viewModel: MovieItemViewModel
        
        @ViewBuilder
        private var headerView: some View {
            VStack {
                ImageView(viewModel.item.getBackdropImage(maxWidth: Int(UIScreen.main.bounds.width)),
                          blurHash: viewModel.item.getBackdropImageBlurHash())

                Spacer()
                    .frame(height: 10)
            }
        }
        
        @ViewBuilder
        private var staticOverlayView: some View {
            ZStack {
                VStack {
                    Spacer()
                    
                    LinearGradient(gradient: Gradient(stops: [
                        .init(color: .systemBackground, location: 0),
                        .init(color: .systemBackground, location: 0.2),
                        .init(color: .systemBackground.opacity(0), location: 1),
                    ]), startPoint: .bottom, endPoint: .top)
                    .frame(height: 100)
                }
                
                VStack {
                    Spacer()
                    
                    ImageView(viewModel.item.getLogoImage(maxWidth: Int(UIScreen.main.bounds.width)),
                              resizingMode: .aspectFit,
                              failureView: {
                                  Text(viewModel.getItemDisplayName())
                                      .font(.largeTitle)
                                      .fontWeight(.semibold)
                                      .multilineTextAlignment(.center)
                                      .foregroundColor(.primary)
                                      .frame(alignment: .bottom)
                              })
                              .frame(height: 100, alignment: .bottom)
                }
            }
        }
        
        var body: some View {
            ParallaxHeaderScrollView(header: headerView,
                                     staticOverlayView: staticOverlayView,
                                     headerHeight: UIScreen.main.bounds.height * 0.25) {
                VStack(alignment: .center) {

                    CompactLogoSubOverlayView(viewModel: viewModel)
                    
                    if let itemOverview = viewModel.item.overview {
                        TruncatedTextView(itemOverview,
                                          lineLimit: 4,
                                          font: UIFont.preferredFont(forTextStyle: .footnote)) {
                            itemRouter.route(to: \.itemOverview, viewModel.item)
                        }
                                          .padding(.horizontal)
                                          .padding(.top)
                    }
                    
                    BodyView()
                        .environmentObject(viewModel)
                }
            }
        }
    }
}
