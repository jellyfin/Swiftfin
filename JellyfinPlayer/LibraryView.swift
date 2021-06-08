/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import NukeUI
import JellyfinAPI

struct LibraryView: View {
    @EnvironmentObject var globalData: GlobalData
    @EnvironmentObject var orientationInfo: OrientationInfo
    
    @State private var items: [BaseItemDto] = []
    @State private var isLoading: Bool = false
    
    var usingParentID: String = ""
    var title: String = ""
    var filters: [ItemFilter] = []
    var personId: String = ""
    var genre: String = ""
    var studio: String = ""
    
    init(usingParentID: String, title: String) {
        self.usingParentID = usingParentID
        self.title = title
    }
    
    init(usingParentID: String, title: String, filters: [ItemFilter]) {
        self.usingParentID = usingParentID
        self.title = title
        self.filters = filters
    }
    
    init(withPerson: BaseItemPerson) {
        self.usingParentID = ""
        self.title = withPerson.name ?? ""
        self.personId = withPerson.id!
    }
    
    init(withGenre: NameGuidPair) {
        self.usingParentID = ""
        self.title = withGenre.name ?? ""
        self.genre = withGenre.id ?? ""
    }
    
    init(withStudio: NameGuidPair) {
        self.usingParentID = ""
        self.title = withStudio.name ?? ""
        self.studio = withStudio.id ?? ""
    }
    
    func onAppear() {
        recalcTracks()
        isLoading = true
        items = []
        
        ItemsAPI.getItemsByUserId(userId: globalData.user.user_id!, limit: 100, recursive: true, searchTerm: nil, sortOrder: [.ascending], fields: [.parentId,.primaryImageAspectRatio,.basicSyncInfo], includeItemTypes: ["Movie","Series"], filters: filters, enableUserData: true, personIds: (personId == "" ? nil : [personId]), studioIds: (studio == "" ? nil : [studio]), genreIds: (genre == "" ? nil : [genre]), enableImages: true)
            .sink(receiveCompletion: { completion in
                HandleAPIRequestCompletion(globalData: globalData, completion: completion)
                isLoading = false
            }, receiveValue: { response in
                items = response.items ?? []
                isLoading = false
            })
            .store(in: &globalData.pendingAPIRequests)
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
            } else {
                if(!items.isEmpty) {
                    VStack {
                        ScrollView(.vertical) {
                            Spacer().frame(height: 16)
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
                                            Text(item.name ?? "")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                            Text(String(item.productionYear ?? 0))
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
        }
        .onAppear(perform: onAppear)
        .navigationBarTitle(title, displayMode: .inline)
    }
}
