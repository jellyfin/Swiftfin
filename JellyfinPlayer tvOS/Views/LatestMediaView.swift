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

    @StateObject var tempViewModel = ViewModel()
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
            UserLibraryAPI.getLatestMedia(userId: SessionManager.main.currentLogin.user.id, parentId: library_id, fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people], enableUserData: true, limit: 12)
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
                    Spacer().frame(width: 45)
                    ForEach(items, id: \.id) { item in
                            NavigationLink(destination: LazyView { ItemView(item: item) }) {
                                PortraitItemElement(item: item)
                            }.buttonStyle(PlainNavigationLinkButtonStyle())
                    }
                    Spacer().frame(width: 45)
                }
            }.frame(height: 396)
            .onAppear(perform: onAppear)
    }
}
