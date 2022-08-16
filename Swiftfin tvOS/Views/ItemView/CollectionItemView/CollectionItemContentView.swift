//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension CollectionItemView {

    struct ContentView: View {

        @ObservedObject
        var viewModel: CollectionItemViewModel
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
                    .focusGuide(focusGuide, tag: "mediaButtons", bottom: "items")
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

                    PosterHStack(title: L10n.items, type: .portrait, items: viewModel.collectionItems)
                        .onSelect { item in
                            itemRouter.route(to: \.item, item)
                        }
                        .focusGuide(focusGuide, tag: "items", top: "mediaButtons", bottom: "about")

                    ItemView.AboutView(viewModel: viewModel)
                        .focusGuide(focusGuide, tag: "about", top: "items")

                    Spacer()
                }
                .frame(minHeight: UIScreen.main.bounds.height)
            }
            .background {
                BlurView(style: .dark)
                    .mask {
                        VStack(spacing: 0) {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.5),
                                    .init(color: .white.opacity(0.8), location: 0.7),
                                    .init(color: .white.opacity(0.8), location: 0.95),
                                    .init(color: .white, location: 1),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: UIScreen.main.bounds.height - 150)

                            Color.white
                        }
                    }
            }
            .onChange(of: focusGuide.focusedTag) { newTag in
                if newTag == "items" && !showLogo {
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
                }
            }
        }
    }
}
