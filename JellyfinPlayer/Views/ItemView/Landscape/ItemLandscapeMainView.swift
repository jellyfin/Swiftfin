//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Stinsen
import SwiftUI

struct ItemLandscapeMainView: View {
    @EnvironmentObject var itemRouter: ItemCoordinator.Router
    @Binding private var videoIsLoading: Bool
    @EnvironmentObject private var viewModel: ItemViewModel
    @EnvironmentObject private var videoPlayerItem: VideoPlayerItem

    init(videoIsLoading: Binding<Bool>) {
        self._videoIsLoading = videoIsLoading
    }

    // MARK: innerBody

    private var innerBody: some View {
        HStack {
            // MARK: Sidebar Image

            VStack {
                ImageView(src: viewModel.item.getPrimaryImage(maxWidth: 130),
                          bh: viewModel.item.getPrimaryImageBlurHash())
                    .frame(width: 130, height: 195)
                    .cornerRadius(10)

                Spacer().frame(height: 15)

                Button {
                    if let playButtonItem = viewModel.playButtonItem {
                        self.videoPlayerItem.itemToPlay = playButtonItem
                        self.videoPlayerItem.shouldShowPlayer = true
                    }
                } label: {
                    // MARK: Play

                    HStack {
                        Image(systemName: "play.fill")
                            .foregroundColor(viewModel.playButtonItem == nil ? Color(UIColor.secondaryLabel) : Color.white)
                            .font(.system(size: 20))
                        Text(viewModel.playButtonText())
                            .foregroundColor(viewModel.playButtonItem == nil ? Color(UIColor.secondaryLabel) : Color.white)
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                    .frame(width: 130, height: 40)
                    .background(viewModel.playButtonItem == nil ? Color(UIColor.secondarySystemFill) : Color.jellyfinPurple)
                    .cornerRadius(10)
                }.disabled(viewModel.playButtonItem == nil)

                Spacer()
            }

            ScrollView {
                VStack(alignment: .leading) {
                    // MARK: ItemLandscapeTopBarView

                    ItemLandscapeTopBarView()
                        .environmentObject(viewModel)

                    // MARK: ItemViewBody

                    if let episodeViewModel = viewModel as? SeasonItemViewModel {
                        EpisodeCardVStackView(items: episodeViewModel.episodes) { episode in
                            itemRouter.route(to: \.item, episode)
                        }
                    } else {
                        ItemViewBody()
                            .environmentObject(viewModel)
                    }
                }
            }
        }
    }

    // MARK: body

    var body: some View {
        VStack {
            ZStack {
                // MARK: Backdrop

                ImageView(src: viewModel.item.getBackdropImage(maxWidth: 200),
                          bh: viewModel.item.getBackdropImageBlurHash())
                    .opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .blur(radius: 8)
                    .layoutPriority(-1)

                // iPadOS is making the view go all the way to the edge.
                // We have to accomodate this here
                if UIDevice.current.userInterfaceIdiom == .pad {
                    innerBody.padding(.horizontal, 25)
                } else {
                    innerBody
                }
            }
        }
    }
}
