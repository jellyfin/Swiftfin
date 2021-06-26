//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import JellyfinAPI

class UpNextViewModel: ObservableObject {
    @Published var largeView: Bool = false
    @Published var item: BaseItemDto? = nil
    
    func episodeAndSeasonNumber() -> String {
        if let pID = item?.parentIndexNumber, let id = item?.indexNumber {
            return "S\(pID):E\(id)"
        }
        return ""
    }
    
    func episodeName() -> String {
        if let name = item?.name {
            return name
        }
        return ""
    }
}

struct VideoUpNextView: View {
    
    @ObservedObject var viewModel: UpNextViewModel
    
    var body: some View {
        
        Button(action: {
            print("Next episode")
        }, label: {
            
            VStack(alignment: viewModel.largeView ? .leading : .center) {
                Text("Up Next")
                    .foregroundColor(.white)
                    .font(viewModel.largeView ? .title : .body)
                
                image
                
                if viewModel.largeView {
                    Text(viewModel.episodeName())
                        .padding(.trailing, 50)
                        .foregroundColor(.white)
                        .font(.title)
                        .lineLimit(1)
                    
                }
            }
            
        })
    }
    
    var image : some View {
        if let url = viewModel.item?.getPrimaryImage(maxWidth: 100) {
            return AnyView(
                ImageView(src: url)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
                    .overlay(overlayIndicator, alignment: .topTrailing))
        }
        else {
            return AnyView(EmptyView())
        }
    }
    
    var overlayIndicator : some View {
        Text(viewModel.episodeAndSeasonNumber())
            .font(viewModel.largeView ? .title3 : .body)
            .foregroundColor(.white)
            .padding(.horizontal, 5)
            .background(Color.black.opacity(0.6))
            .cornerRadius(5)
            .padding(5)
        
    }
}
