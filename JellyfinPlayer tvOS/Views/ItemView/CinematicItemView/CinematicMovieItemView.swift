//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Introspect
import SwiftUI

struct CinematicMovieItemView: View {
    
    @ObservedObject var viewModel: MovieItemViewModel
    @State var verticalScrollViewOffset: CGFloat = 0
    @State var wrappedScrollView: UIScrollView?
    
    var body: some View {
        ZStack {
            
            VStack {
                Spacer()
                
                GeometryReader { overlayGeoReader in
                    Text("")
                        .onAppear {
                            self.verticalScrollViewOffset = overlayGeoReader.frame(in: .global).origin.y + overlayGeoReader.frame(in: .global).height - 200
                        }
                }
                .frame(height: 50)
            }
            
            ImageView(src: viewModel.item.getBackdropImage(maxWidth: 1920),
                      bh: viewModel.item.getBackdropImageBlurHash())
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    
                    Spacer(minLength: verticalScrollViewOffset)
                    
                    CinematicItemViewTopRow(viewModel: viewModel, wrappedScrollView: wrappedScrollView)
                        .focusSection()

                    ZStack(alignment: .topLeading) {
                        
                        Color.black.ignoresSafeArea()
                        
                        VStack(alignment: .leading, spacing: 20) {
                            
                            CinematicItemAboutView(viewModel: viewModel)
                            
                            if !viewModel.similarItems.isEmpty {
                                PortraitItemsRowView(rowTitle: "Recommended", items: viewModel.similarItems)
                            }
                            
                            ItemDetailsView(viewModel: viewModel)
                            
//                            HStack {
//                                SFSymbolButton(systemName: "heart.fill", pointSize: 48, action: {})
//                                    .frame(width: 60, height: 60)
//                                SFSymbolButton(systemName: "checkmark.circle", pointSize: 48, action: {})
//                                    .frame(width: 60, height: 60)
//                            }
//                            .padding(.horizontal, 50)
                        }
                        .padding(.top, 50)
                        
                    }
                }
            }
            .introspectScrollView { scrollView in
                wrappedScrollView = scrollView
            }
            .ignoresSafeArea()
        }
    }
}
