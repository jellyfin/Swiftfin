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

class ItemViewModel : ObservableObject {
    let item: BaseItemDto
    @Published var showVideoPlayer = false

    
    init(item: BaseItemDto) {
        self.item = item
    }
    
    func getTitle() -> String {
        if item.type == "Episode" {
            return "S\(item.parentIndexNumber ?? 0) • E\(item.indexNumber ?? 0) - \(item.name ?? "")"
        }
        else {
            return item.name!
        }
    }
    
    func getYearOrDate() -> String {
        if item.type == "Episode" {
            if let dateString = item.premiereDateToString() {
                return dateString
            }
        }
        return String(item.productionYear!)
    }
}

struct ItemView: View {
    @ObservedObject var viewModel : ItemViewModel
    
    init(item: BaseItemDto) {
        viewModel = ItemViewModel(item: item)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                topImage(viewModel: viewModel)
                // If item is episode show the season to scroll through horizontally
                Button("Test") {
                    
                }
                
                // Actor row
                
                // Related media row
            }
        }
    }
    
    struct topImage: View {
        @ObservedObject var viewModel : ItemViewModel
        
        var body: some View {
            ZStack {
                image
                VStack(alignment: .leading) {
                    Spacer()
                    
                    Text(viewModel.getTitle())
                        .font(.title2)
                        .shadow(radius: 15)
                    
                    HStack {
                        NavigationLink(destination: VideoPlayerView(item: viewModel.item)) {
                            Text("Play")
                                .padding(.horizontal, 50)
                        }
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Text(viewModel.item.getItemRuntime())
                                Text(viewModel.getYearOrDate())
                                if let rating = viewModel.item.officialRating {
                                    Text(rating)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                                        .overlay(RoundedRectangle(cornerRadius: 2)
                                                    .stroke(Color.secondary, lineWidth: 1))
                                }
                            }
                            .padding(.vertical)
                            
                            Text(viewModel.item.overview ?? "")
                        }
                        
                    }
                    
                }
                .padding([.leading, .bottom], 100)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(gradient: Gradient(colors: [.black, .black.opacity(0)]), startPoint: .bottom, endPoint: .top))
            }
        }
        
        var image : some View {
            let width = UIScreen.main.bounds.width
            return ImageView(src: viewModel.item.getSeriesBackdropImage(maxWidth: Int(width)), bh: viewModel.item.getSeriesBackdropImageBlurHash())
                .frame(width: width, height: UIScreen.main.bounds.height)
        }
        
    }
    
}
