/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import JellyfinAPI
import Combine

struct SeriesItemView: View {
    @StateObject
    var tempViewModel = ViewModel()

    var item: BaseItemDto

    @State private var seasons: [BaseItemDto] = []
    @State private var isLoading: Bool = true
    @State private var viewDidLoad: Bool = false

    func onAppear() {
        recalcTracks()
        if viewDidLoad {
            return
        }

        isLoading = true
        

        DispatchQueue.global(qos: .userInitiated).async {
            TvShowsAPI.getSeasons(seriesId: item.id ?? "", fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people])
                .sink(receiveCompletion: { completion in
                    print(completion)
                }, receiveValue: { response in
                    isLoading = false
                    viewDidLoad = true
                    seasons = response.items ?? []
                })
                .store(in: &tempViewModel.cancellables)
        }
    }

    // MARK: Grid tracks
    func recalcTracks() {
        let trkCnt: Int = Int(floor(UIScreen.main.bounds.size.width / 125))
        tracks = []
        for _ in (0..<trkCnt) {
            tracks.append(GridItem.init(.flexible()))
        }
    }
    @State private var tracks: [GridItem] = []

    var body: some View {
        if isLoading {
            ProgressView()
            .onAppear(perform: onAppear)
        } else {
            ScrollView(.vertical) {
                Spacer().frame(height: 16)
                LazyVGrid(columns: tracks) {
                    ForEach(seasons, id: \.id) { season in
                        NavigationLink(destination: ItemView(item: season)) {
                            VStack(alignment: .leading) {
                                ImageView(src: season.getPrimaryImage(baseURL: ServerEnvironment.current.server.baseURI!, maxWidth: 100), bh: season.getPrimaryImageBlurHash())
                                    .frame(width: 100, height: 150)
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                                Text(season.name ?? "")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                if season.productionYear != nil {
                                    Text(String(season.productionYear!))
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }.frame(width: 100)
                        }
                    }
                    Spacer().frame(height: 2)
                }.onRotate { _ in
                    recalcTracks()
                }
            }
            .overrideViewPreference(.unspecified)
            .navigationTitle(item.name ?? "")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
