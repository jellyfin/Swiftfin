//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct OfflineItemView: View {
    
    @EnvironmentObject
    var offlineItemRouter: OfflineItemCoordinator.Router
    
    let offlineItem: OfflineItem
    
    @ViewBuilder
    private var portraitHeaderView: some View {
        ImageView(src: offlineItem.backdropImageURL ?? URL(fileURLWithPath: ""))
            .opacity(0.4)
            .blur(radius: 2.0)
            .accessibilityIgnoresInvertColors()
            .frame(maxHeight: 500)
    }
    
    @ViewBuilder
    private var portraitStaticOverlayView: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .bottom, spacing: 12) {

                // MARK: Portrait Image

                ImageView(src: offlineItem.primaryImageURL ?? URL(fileURLWithPath: ""))
                    .portraitPoster(width: 130)
                    .accessibilityIgnoresInvertColors()

                VStack(alignment: .leading, spacing: 1) {
                    Spacer()

                    // MARK: Name

                    Text(offlineItem.item.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 10)
                    
                    HStack {
                        if offlineItem.item.unaired {
                            if let premiereDateLabel = offlineItem.item.airDateLabel {
                                Text(premiereDateLabel)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        if let runtime = offlineItem.item.getItemRuntime() {
                            Text(runtime)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        if let productionYear = offlineItem.item.productionYear {
                            Text(String(productionYear))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        if let officialRating = offlineItem.item.officialRating {
                            Text(officialRating)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                                .overlay(RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.secondary, lineWidth: 1))
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? -189 : -64)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            // MARK: ParallaxScrollView

            ParallaxHeaderScrollView(header: portraitHeaderView,
                                     staticOverlayView: portraitStaticOverlayView,
                                     overlayAlignment: .bottomLeading,
                                     headerHeight: UIScreen.main.bounds.width * 0.5625) {
                VStack {
                    Spacer()
                        .frame(height: 70)

                    Button {
                        let viewModel = offlineItem.item.createVideoPlayerViewModel(from: offlineItem.playbackInfo)[0]
                        viewModel.setNetworkType(.offline)
                        viewModel.injectCustomValues(startFromBeginning: true)
                        offlineItemRouter.route(to: \.videoPlayer, viewModel)
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                                .foregroundColor(Color.white)
                                .font(.system(size: 20))
                            L10n.play.text
                                .foregroundColor(Color.white)
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                        .frame(width: 300, height: 50)
                        .background(Color.jellyfinPurple)
                        .cornerRadius(10)
                    }
                    .frame(alignment: .center)
                }
            }
        }
    }
}
