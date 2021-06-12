/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import JellyfinAPI

struct LibrarySearchView: View {
    @EnvironmentObject var globalData: GlobalData
    @EnvironmentObject var orientationInfo: OrientationInfo

    @State private var items: [BaseItemDto] = []
    @State private var searchQuery: String = ""
    @State private var isLoading: Bool = false
    private var usingParentID: String = ""
    @State private var lastSearchTime: Double = CACurrentMediaTime()

    init(usingParentID: String) {
        self.usingParentID = usingParentID
    }

    func onAppear() {
        recalcTracks()
        requestSearch(query: "")
    }

    func requestSearch(query: String) {
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async {
            ItemsAPI.getItemsByUserId(userId: globalData.user.user_id!, limit: 60, recursive: true, searchTerm: query, sortOrder: [.ascending], parentId: (usingParentID != "" ? usingParentID : nil), fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people], includeItemTypes: ["Movie", "Series"], sortBy: ["SortName"], enableUserData: true, enableImages: true)
                .sink(receiveCompletion: { completion in
                    HandleAPIRequestCompletion(globalData: globalData, completion: completion)
                }, receiveValue: { response in
                    items = response.items ?? []
                    isLoading = false
                })
                .store(in: &globalData.pendingAPIRequests)
        }
    }

    // MARK: tracks for grid
    @State private var tracks: [GridItem] = []
    func recalcTracks() {
        let trkCnt = Int(floor(UIScreen.main.bounds.size.width / 125))
        tracks = []
        for _ in 0 ..< trkCnt {
            tracks.append(GridItem(.flexible()))
        }
    }

    var body: some View {
        VStack {
            Spacer().frame(height: 6)
            SearchBar(text: $searchQuery)
            if isLoading == true {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                if !items.isEmpty {
                    ScrollView(.vertical) {
                        Spacer().frame(height: 16)
                        LazyVGrid(columns: tracks) {
                            ForEach(items, id: \.id) { item in
                                NavigationLink(destination: ItemView(item: item)) {
                                    VStack(alignment: .leading) {
                                        ImageView(src: item.getPrimaryImage(baseURL: globalData.server.baseURI!, maxWidth: 100), bh: item.getPrimaryImageBlurHash())
                                            .frame(width: 100, height: 150)
                                            .cornerRadius(10)
                                        Text(item.name ?? "")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        if item.productionYear != nil {
                                            Text(String(item.productionYear!))
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        } else {
                                            Text(item.type ?? "")
                                        }
                                    }.frame(width: 100)
                                }
                            }
                        }
                        Spacer().frame(height: 16)
                            .onChange(of: orientationInfo.orientation) { _ in
                            recalcTracks()
                        }
                    }
                } else {
                    Text("No results :(")
                }
            }
        }
        .onAppear(perform: onAppear)
        .navigationBarTitle("Search", displayMode: .inline)
        .onChange(of: searchQuery) { query in
            if CACurrentMediaTime() - lastSearchTime > 0.5 {
                lastSearchTime = CACurrentMediaTime()
                requestSearch(query: query)
            }
        }
    }
}

// stream NM5 by nicki!
