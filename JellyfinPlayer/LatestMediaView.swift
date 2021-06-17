/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import JellyfinAPI
import Combine

struct LatestMediaView: View {

    @StateObject
    var tempViewModel = ViewModel()
    @State var items: [BaseItemDto] = []
    private var library_id: String = ""
    @State private var viewDidLoad: Bool = false

    init(usingParentID: String) {
        library_id = usingParentID
    }

    func onAppear() {
        if viewDidLoad == true {
            return
        }
        viewDidLoad = true

        DispatchQueue.global(qos: .userInitiated).async {
            UserLibraryAPI.getLatestMedia(userId: SessionManager.current.user.user_id!, parentId: library_id, fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people], enableUserData: true, limit: 12)
                .sink(receiveCompletion: { completion in
                    print(completion)
                }, receiveValue: { response in
                    items = response
                })
                .store(in: &tempViewModel.cancellables)
        }
    }

    var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    Spacer().frame(width: 16)
                    ForEach(items, id: \.id) { item in
                        if item.type == "Series" || item.type == "Movie" {
                            NavigationLink(destination: ItemView(item: item)) {
                                VStack(alignment: .leading) {
                                    Spacer().frame(height: 10)
                                    ImageView(src: item.getPrimaryImage(baseURL: ServerEnvironment.current.server.baseURI!, maxWidth: 100), bh: item.getPrimaryImageBlurHash())
                                        .frame(width: 100, height: 150)
                                        .cornerRadius(10)
                                    Spacer().frame(height: 5)
                                    Text(item.seriesName ?? item.name ?? "")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    if item.productionYear != nil {
                                        Text(String(item.productionYear ?? 0))
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    } else {
                                        Text(item.type!)
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
