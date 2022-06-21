//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {
    
    struct ActionButtonHStack: View {
        
        @ObservedObject
        var viewModel: ItemViewModel
        
        var body: some View {
            HStack(alignment: .center, spacing: 15) {
                Button {
                    UIDevice.impact(.light)
                    viewModel.toggleWatchState()
                } label: {
                    if viewModel.isWatched {
                        Image(systemName: "checkmark.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color.jellyfinPurple, Color.jellyfinPurple)
                    } else {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(.white, Color(UIColor.lightGray), Color(UIColor.lightGray))
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button {
                    UIDevice.impact(.light)
                    viewModel.toggleFavoriteState()
                } label: {
                    if viewModel.isFavorited {
                        Image(systemName: "heart.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color.red, Color.red)
                    } else {
                        Image(systemName: "heart")
                            .foregroundStyle(.white, Color(UIColor.lightGray), Color(UIColor.lightGray))
                    }
                }
                .frame(maxWidth: .infinity)
                
                if viewModel.videoPlayerViewModels.count > 1 {
                    Menu {
                        ForEach(viewModel.videoPlayerViewModels, id: \.versionName) { viewModelOption in
                            Button {
                                viewModel.selectedVideoPlayerViewModel = viewModelOption
                            } label: {
                                if viewModelOption.versionName == viewModel.selectedVideoPlayerViewModel?.versionName {
                                    Label(viewModelOption.versionName ?? L10n.noTitle, systemImage: "checkmark")
                                } else {
                                    Text(viewModelOption.versionName ?? L10n.noTitle)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "list.dash")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .font(.title)
        }
    }
}
