//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemVideoPlayer.Overlay {
    
    struct ChapterOverlay: View {
        
        @EnvironmentObject
        private var viewModel: ItemVideoPlayerViewModel
        @EnvironmentObject
        private var secondsHandler: CurrentSecondsHandler
        
        var body: some View {
            VStack {
                Spacer()
                
                PosterHStack(
                    title: L10n.chapters,
                    type: .landscape,
                    items: viewModel.chapters)
                .imageOverlay { type in
                    if case let PosterButtonType.item(info) = type, info.secondsRange.contains(secondsHandler.currentSeconds) {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.jellyfinPurple, lineWidth: 8)
                    }
                }
                .content { type in
                    if case let PosterButtonType.item(info) = type {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(info.chapterInfo.displayName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .foregroundColor(.white)
                            
                            Text(info.chapterInfo.timestampLabel)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(UIColor.systemBlue))
                                .padding(.vertical, 2)
                                .padding(.horizontal, 4)
                                .background {
                                    Color(UIColor.darkGray).opacity(0.2).cornerRadius(4)
                                }
                        }
                    }
                }
                .onSelect { info in
                    let seconds = Int32(info.chapterInfo.startTimeSeconds)
                    viewModel.eventSubject.send(.setTime(.seconds(seconds)))
                }
                .background {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black.opacity(0.7), location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
        }
    }
}
