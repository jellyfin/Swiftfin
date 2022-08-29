//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CollectionView
import JellyfinAPI
import Stinsen
import SwiftUI

struct LibraryListView: View {
    
    @EnvironmentObject
    private var router: LibraryListCoordinator.Router
    @ObservedObject
    var viewModel: LibraryListViewModel
    
    private var libraryItems: [LibraryItem] {
        [LibraryItem(library: .init(name: L10n.favorites, id: "favorites"), viewModel: viewModel)] +
        viewModel.libraries.map { LibraryItem(library: $0, viewModel: viewModel) }
    }
    
    private var gridLayout: NSCollectionLayoutSection.GridLayoutMode {
        if UIDevice.isPhone {
            return .fixedNumberOfColumns(2)
        } else {
            return .adaptive(withMinItemSize: PosterType.landscape.width + 10)
        }
    }
    
    var body: some View {
        CollectionView(items: libraryItems) { _, item, _ in
            PosterButton(item: item, type: .landscape)
                .onSelect { _ in
                    if item.library.id == "favorites" {
                        router.route(to: \.library, (viewModel: .init(filters: .favorites), title: ""))
                    } else {
                        router.route(to: \.library, (viewModel: .init(parentID: item.library.id), title: ""))
                    }
                }
                .imageOverlay { _ in
                    ZStack {
                        Color.black
                            .opacity(0.5)
                        
                        Text(item.library.displayName)
                            .foregroundColor(.white)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(alignment: .center)
                    }
                }
                .scaleItem(UIDevice.isPhone ? 0.9 : 1)
        }
        .layout { _, layoutEnvironment in
            .grid(
                layoutEnvironment: layoutEnvironment,
                layoutMode: gridLayout,
                sectionInsets: .init(top: 0, leading: 10, bottom: 0, trailing: 10)
            )
        }
        .configure { configuration in
            configuration.showsVerticalScrollIndicator = false
        }
        .ignoresSafeArea()
        .navigationTitle(L10n.allMedia)
    }
    
    struct LibraryItem: Equatable, Poster {
        
        var library: BaseItemDto
        var viewModel: LibraryListViewModel
        var title: String = ""
        var subtitle: String?
        var showTitle: Bool = false

        func portraitPosterImageSource(maxWidth: CGFloat) -> ImageSource {
            .init()
        }
        
        func landscapePosterImageSources(maxWidth: CGFloat, single: Bool) -> [ImageSource] {
            return viewModel.libraryImages[library.id ?? ""] ?? []
        }
        
        static func == (lhs: LibraryListView.LibraryItem, rhs: LibraryListView.LibraryItem) -> Bool {
            return lhs.library == rhs.library &&
            lhs.viewModel.libraryImages[lhs.library.id ?? ""] == rhs.viewModel.libraryImages[rhs.library.id ?? ""]
        }
    }
}
