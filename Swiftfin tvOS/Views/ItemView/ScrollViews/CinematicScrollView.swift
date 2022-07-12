//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Introspect
import SwiftUI

extension ItemView {
    
    struct CinematicScrollView<Content: View>: View {
        
        @ObservedObject
        var viewModel: ItemViewModel
        @State
        var wrappedScrollView: UIScrollView?
        
        let content: () -> Content
        
        var body: some View {
            
            ZStack {
                
                ImageView(viewModel.item.getBackdropImage(maxWidth: 1920),
                          blurHash: viewModel.item.getBackdropImageBlurHash())
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        
                        StaticOverlayView(viewModel: viewModel,
                                          wrappedScrollView: wrappedScrollView)
                        .focusSection()
                        .frame(height: UIScreen.main.bounds.height - 50)
                        
                        ZStack {
                            BlurView()
                            
                            content()
                                .focusSection()
                        }
                        .frame(minHeight: UIScreen.main.bounds.height)
                    }
                }
                .introspectScrollView { scrollView in
                    wrappedScrollView = scrollView
                }
                .ignoresSafeArea()
            }
        }
    }
}

extension ItemView.CinematicScrollView {
    
    struct StaticOverlayView: View {
        
        @EnvironmentObject
        private var itemRouter: ItemCoordinator.Router
        @ObservedObject
        var viewModel: ItemViewModel
        @State
        var wrappedScrollView: UIScrollView?
        @FocusState
        private var actionButtonHStackFocused: Bool
        
        var body: some View {
            VStack {
                Spacer()
                
                HStack {
                    
                    VStack {
                        ItemView.PlayButton(viewModel: viewModel)
                        
                        ItemView.ActionButtonHStack(viewModel: viewModel)
                            .focusSection()
                    }
                    
                    VStack(alignment: .leading) {
                        Text(viewModel.item.displayName)
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.white)
                        
                        DotHStack {
                            if let firstGenre = viewModel.item.genres?.first {
                                Text(firstGenre)
                            }

                            if let premiereYear = viewModel.item.premiereDateYear {
                                Text(String(premiereYear))
                            }

                            if let playButtonitem = viewModel.playButtonItem, let runtime = playButtonitem.getItemRuntime() {
                                Text(runtime)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(Color(UIColor.lightGray))
                        
                        ItemView.AttributesHStack(viewModel: viewModel)
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 50)
                .padding(.top, 70)
                .padding(.bottom, 50)
                .background {
                    Color.black
                        .mask {
                            LinearGradient(gradient: Gradient(stops: [
                                .init(color: .white, location: 0),
                                .init(color: .white, location: 0.5),
                                .init(color: .white.opacity(0), location: 1),
                            ]), startPoint: .bottom, endPoint: .top)
                        }
                }
            }
        }
    }
}

extension VerticalAlignment {

    private struct PlayInformationAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.bottom]
        }
    }

    static let PlayInformationAlignmentGuide = VerticalAlignment(PlayInformationAlignment.self)
}
