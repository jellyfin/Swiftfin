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

    struct ContentView: View {

        @ObservedObject
        var viewModel: SeriesItemViewModel
        @State
        var scrollViewProxy: ScrollViewProxy

        @EnvironmentObject
        private var itemRouter: ItemCoordinator.Router
        @ObservedObject
        private var focusGuide = FocusGuide()
        @State
        private var showLogo: Bool = false

        var body: some View {
            VStack(spacing: 0) {

                ItemView.CinematicHeaderView(viewModel: viewModel)
                    .focusGuide(focusGuide, tag: "mediaButtons", bottom: "seasons")
                    .frame(height: UIScreen.main.bounds.height - 150)
                    .padding(.bottom, 50)

                VStack(spacing: 0) {

                    Color.clear
                        .frame(height: 0.5)
                        .id("topContentDivider")

                    if showLogo {
                        ImageView(viewModel.item.imageSource(.logo, maxWidth: 500, maxHeight: 150))
                            .resizingMode(.aspectFit)
                            .failure {
                                Text(viewModel.item.displayName)
                                    .font(.largeTitle)
                                    .fontWeight(.semibold)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.white)
                            }
                            .frame(width: 500, height: 150)
                            .padding(.top, 5)
                    }

                    SeriesEpisodesView(viewModel: viewModel)
                        .environmentObject(focusGuide)

                    Color.clear
                        .frame(height: 0.5)
                        .id("seasonsRecommendedContentDivider")

                    PosterHStack(title: L10n.recommended, type: .portrait, items: viewModel.similarItems)
                        .onSelect { item in
                            itemRouter.route(to: \.item, item)
                        }
                        .focusGuide(focusGuide, tag: "recommended", top: "seasons", bottom: "about")

                    ItemView.AboutView(viewModel: viewModel)
                        .focusGuide(focusGuide, tag: "about", top: "recommended")

                    Spacer()
                }
                .frame(minHeight: UIScreen.main.bounds.height)
            }
            .background {
                BlurView(style: .dark)
                    .mask {
                        VStack(spacing: 0) {
                            LinearGradient(gradient: Gradient(stops: [
                                .init(color: .white, location: 0),
                                .init(color: .white.opacity(0.7), location: 0.4),
                                .init(color: .white.opacity(0), location: 1),
                            ]), startPoint: .bottom, endPoint: .top)
                                .frame(height: UIScreen.main.bounds.height - 150)

                            Color.white
                        }
                    }
            }
            .onChange(of: focusGuide.focusedTag) { newTag in
                if newTag == "seasons" && !showLogo {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.easeIn(duration: 0.35)) {
                            scrollViewProxy.scrollTo("topContentDivider")
                        }
                    }
                    withAnimation {
                        self.showLogo = true
                    }
                } else if newTag == "mediaButtons" {
                    withAnimation {
                        self.showLogo = false
                    }
                } else if newTag == "recommended" && focusGuide.lastFocusedTag == "episodes" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.easeIn(duration: 0.35)) {
                            scrollViewProxy.scrollTo("seasonsRecommendedContentDivider")
                        }
                    }
                }
            }
        }
    }
}
