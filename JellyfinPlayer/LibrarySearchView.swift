/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import NukeUI
import JellyfinAPI

struct LibrarySearchView: View {
    @EnvironmentObject var globalData: GlobalData
    @EnvironmentObject var orientationInfo: OrientationInfo
    
    @State private var items: [BaseItemDto] = []
    @State private var searchQuery: String = ""
    @State private var isLoading: Bool = false
    
    var usingParentID: String

    func onAppear() {
        recalcTracks()
        requestSearch(query: "")
    }
    
    func requestSearch(query: String) {
        isLoading = true
        ItemsAPI.getItems(userId: globalData.user.user_id!, searchTerm: query, parentId: usingParentID)
            .sink(receiveCompletion: { completion in
                HandleAPIRequestCompletion(globalData: globalData, completion: completion)
            }, receiveValue: { response in
                items = response.items!
            })
            .store(in: &globalData.pendingAPIRequests)
        
        isLoading = false
    }
    
    //MARK: tracks for grid
    @State private var tracks: [GridItem] = []
    func recalcTracks() {
        let trkCnt = Int(floor(UIScreen.main.bounds.size.width / 125))
        _tracks.wrappedValue = []
        for _ in 0 ..< trkCnt {
            _tracks.wrappedValue.append(GridItem(.flexible()))
        }
    }

    var body: some View {
        ZStack {
            if(isLoading == true) {
                ProgressView()
            }
            if(!items.isEmpty) {
                VStack {
                    Spacer().frame(height: 6)
                    TextField("Search", text: $searchQuery)
                        .padding(.horizontal, 10)
                        .foregroundColor(Color.secondary)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    ScrollView(.vertical) {
                        LazyVGrid(columns: tracks) {
                            ForEach(items, id: \.id) { item in
                                NavigationLink(destination: ItemView(item: item)) {
                                    VStack(alignment: .leading) {
                                        LazyImage(source: item.getPrimaryImage(baseURL: globalData.server.baseURI!, maxWidth: 100))
                                            .placeholderAndFailure {
                                                Image(uiImage: UIImage(blurHash: item.getPrimaryImageBlurHash(),
                                                    size: CGSize(width: 32, height: 32))!)
                                                    .resizable()
                                                    .frame(width: 100, height: 150)
                                                    .cornerRadius(10)
                                            }
                                            .frame(width: 100, height: 150)
                                            .cornerRadius(10)
                                        Text(item.name!)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        Text(String(item.productionYear!))
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }.frame(width: 100)
                                }
                            }
                        }.onChange(of: orientationInfo.orientation) { _ in
                            recalcTracks()
                        }
                    }
                }
            } else {
                Text("No results found :(")
            }
        }
        .onAppear(perform: onAppear)
        .navigationBarTitle("Search", displayMode: .inline)
        .onChange(of: searchQuery) { query in
            requestSearch(query: query)
        }
    }
}
