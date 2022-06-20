//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct PortraitCompactOverlayView: View {

	@EnvironmentObject
	var itemRouter: ItemCoordinator.Router
	@ObservedObject
	private var viewModel: ItemViewModel
    
    init(viewModel: ItemViewModel) {
        self.viewModel = viewModel
    }
    
    @ViewBuilder
    private var rightShelfView: some View {
        VStack(alignment: .leading) {
            Spacer()

            // MARK: Name

            Text(viewModel.getItemDisplayName())
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            // MARK: Details

            HStack {
                if viewModel.item.unaired {
                    if let premiereDateLabel = viewModel.item.airDateLabel {
                        Text(premiereDateLabel)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                } else {
                    if let productionYear = viewModel.item.productionYear {
                        Text(String(productionYear))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                if let playButtonitem = viewModel.playButtonItem, let runtime = playButtonitem.getItemRuntime() {
                    Circle()
                        .foregroundColor(.secondary)
                        .frame(width: 2, height: 2)
                        .padding(.horizontal, 1)
                    
                    Text(runtime)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            
            ItemView.AttributesHStackView()
                .environmentObject(viewModel)
        }
    }

	var body: some View {
        VStack(alignment: .leading, spacing: 10) {
			HStack(alignment: .bottom, spacing: 12) {

				// MARK: Portrait Image

				ImageView(viewModel.item.portraitHeaderViewURL(maxWidth: 130),
				          blurHash: viewModel.item.getPrimaryImageBlurHash())
					.portraitPoster(width: 130)
					.accessibilityIgnoresInvertColors()

				rightShelfView
                    .padding(.bottom)
			}

            // MARK: Play
            
            HStack(alignment: .center) {
                
                ItemView.PlayButton(viewModel: viewModel)
                    .frame(width: 130, height: 40)
                
                Spacer()

                // MARK: Watched
                Button {
                    viewModel.toggleWatchState()
                } label: {
                    if viewModel.isWatched {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.jellyfinPurple)
                            .font(.system(size: 20))
                    } else {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(Color.primary)
                            .font(.system(size: 20))
                    }
                }
                .disabled(viewModel.isLoading)
                
                Button {
                    viewModel.toggleFavoriteState()
                } label: {
                    if viewModel.isFavorited {
                        Image(systemName: "heart.fill")
                            .foregroundColor(Color(UIColor.systemRed))
                            .font(.system(size: 20))
                    } else {
                        Image(systemName: "heart")
                            .foregroundColor(Color.primary)
                            .font(.system(size: 20))
                    }
                }
                .disabled(viewModel.isLoading)
            }
		}
		.padding(.horizontal)
        .background {
            Color.systemBackground
                .mask {
                    LinearGradient(gradient: Gradient(stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white, location: 0.2),
                        .init(color: .white.opacity(0), location: 1),
                    ]), startPoint: .bottom, endPoint: .top)
                }
        }
	}
}
