//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import JellyfinAPI
import SwiftUI

struct SmallMediaStreamSelectionView: View {
    
    @ObservedObject var viewModel: VideoPlayerViewModel
    let title: String
    var items: [MediaStream]
    var selectedAction: (MediaStream) -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.9)]),
                           startPoint: .top,
                           endPoint: .bottom)
                .ignoresSafeArea()
                .frame(height: 150)
            
            VStack {
                
                Spacer()
                
                HStack {
                    Text("Subtitles")

                    Spacer()
                }
                
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(items, id: \.self) { item in
                            Button {
                                viewModel.playerOverlayDelegate?.didSelectSubtitleStream(index: item.index ?? -1)
                            } label: {
                                if item.index ?? -1 == viewModel.selectedSubtitleStreamIndex {
                                    Label(item.displayTitle ?? "No Title", systemImage: "checkmark")
                                } else {
                                    Text(item.displayTitle ?? "No Title")
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 100)
            }
        }
    }
}
