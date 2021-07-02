//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI

struct VideoPlayerUpNextView: View {
    
    @ObservedObject var viewModel: UpNextViewModel
    
    var body: some View {
        VStack {
            // Just played and up next
            HStack {
                VStack(alignment: .leading) {
                    Text("JUST PLAYED")
                    Rectangle()
                        .frame(width: 555, height: 310, alignment: .leading)
                    VStack(alignment: .center) {
                        Text((viewModel.currentItem?.seriesName) ?? "")
                        Text((viewModel.currentItem?.getEpisodeLocator()) ?? "")
                    }
                }
                
                nextEpView
                
            }
            
            Spacer()
            
            // On deck
            HStack {
                Text("ON DECK")
                Button("Test") {
                    print("test")
                }
            }
        }
    }
    
    
    var nextEpView: some View {
        Button(action: {}, label: {
            VStack(alignment: .leading) {
                Text("UP NEXT")
                HStack {
                    if let url = viewModel.item?.getPrimaryImage(maxWidth: 400) {
                        ImageView(src: url)
                            .frame(maxWidth: 400)
                            .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
                    }
                    VStack {
                        Text(viewModel.item?.name ?? "")
                        Text(viewModel.item?.overview ?? "")
                    }
                }
                VStack(alignment: .center) {
                    Text((viewModel.item?.seriesName) ?? "")
                    Text((viewModel.item?.getEpisodeLocator()) ?? "")
                    
                }
            }
        })

    }
}
