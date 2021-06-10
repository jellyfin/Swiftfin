/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import NukeUI
import JellyfinAPI

struct LatestMediaView: View {
    @EnvironmentObject var globalData: GlobalData
    
    @State var items: [BaseItemDto] = []
    private var library_id: String = "";
    @State private var viewDidLoad: Bool = false;
    
    init(usingParentID: String) {
        library_id = usingParentID;
    }
    
    func onAppear() {
        if(viewDidLoad == true) {
            return
        }
        viewDidLoad = true;
        
        UserLibraryAPI.getLatestMedia(userId: globalData.user.user_id!, parentId: library_id, fields: [.primaryImageAspectRatio,.seriesPrimaryImage,.seasonUserData,.overview,.genres,.people], enableUserData: true, limit: 12)
            .sink(receiveCompletion: { completion in
                HandleAPIRequestCompletion(globalData: globalData, completion: completion)
            }, receiveValue: { response in
                items = response
            })
            .store(in: &globalData.pendingAPIRequests)
    }
    
    var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack() {
                    Spacer().frame(width:16)
                    ForEach(items, id: \.id) { item in
                        if(item.type == "Series" || item.type == "Movie" || item.type == "Episode") {
                            NavigationLink(destination: ItemView(item: item)) {
                                VStack(alignment: .leading) {
                                    Spacer().frame(height:10)
                                    LazyImage(source: (item.type != "Episode" ? item.getPrimaryImage(baseURL: globalData.server.baseURI!, maxWidth: 100) : item.getSeriesPrimaryImage(baseURL: globalData.server.baseURI!, maxWidth: 100)))
                                        .placeholderAndFailure {
                                            Image(uiImage: UIImage(blurHash: item.getPrimaryImageBlurHash(), size: CGSize(width: 16, height: 20))!)
                                                .resizable()
                                                .frame(width: 100, height: 150)
                                                .cornerRadius(10)
                                        }
                                        .frame(width: 100, height: 150)
                                        .cornerRadius(10)
                                    Spacer().frame(height:5)
                                    Text(item.seriesName ?? item.name ?? "")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    if(item.type == "Episode") {
                                        Text("S\(String(item.parentIndexNumber ?? 0)):E\(String(item.indexNumber ?? 0))")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    } else {
                                        Text(String(item.productionYear ?? 0))
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }.frame(width: 100)
                                Spacer().frame(width: 15)
                            }
                        }
                    }
                }
                .frame(height: 190)
            }
            .onAppear(perform: onAppear)
            .padding(EdgeInsets(top: -2, leading: 0, bottom: 0, trailing: 0)).frame(height: 190)
    }
}
