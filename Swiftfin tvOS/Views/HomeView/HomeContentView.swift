//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension HomeView {
    struct ContentView: View {
        @ObservedObject var viewModel: HomeViewModel
        
        @FocusState private var focusedSection: FocusSection?
        @FocusState private var focusedImage: String?
        
        @State private var enlargedItem: BaseItemDto?
        @State private var hasHero = true
        @State private var heroVisible = true
        
        @State var recentlyAddedViewModel: ItemTypeLibraryViewModel?
        @State var recentlyAddedLibrariesViewModels: [String: LibraryViewModel] = [:]

        var body: some View {
            GeometryReader { geoReader in
                ScrollView(.vertical) {
                    ScrollViewReader { scrollView in
                        let heroContent: [BaseItemDto] = viewModel.resumeItems + viewModel.nextUpItems
                        
                        // Hero section
                        if hasHero {
                            // Substract the hight of the first column plus the hight of its text (20) and a bit of spacing from the hight of the screen
                            // Because all tvOS devices are 16:9 and use the same amount of points at any resolution this is fine
                            Spacer(minLength: UIScreen.main.bounds.height - ((HomeItemRow.Columns.five.rawValue / (16 / 9)) * 1.11 + (heroVisible ? 230 : 125) - 20))
                                .id(FocusSection.spacer)
                            
                            VStack {
                                HomeSectionText(title: L10n.nextUp, visible: !heroVisible)
                                HomeItemRow(items: heroContent, size: .five, focusPrefix: "hero", focusedImage: $focusedImage)
                            }
                            .id(FocusSection.hero)
                            .focused($focusedSection, equals: .hero)
                            .focusSection()
                            .padding(.bottom, heroVisible ? -25 : 0)
                            .onAppear {
                                hasHero = !heroContent.isEmpty
                                
                                if hasHero {
                                    enlargedItem = heroContent[0]
                                }
                            }
                        }
                        
                        // Content section
                        Group {
                            if let recentlyAddedViewModel = recentlyAddedViewModel {
                                HomeRecentlyAdded(viewModel: recentlyAddedViewModel, hasHero: $hasHero, heroVisible: $heroVisible, focusedImage: $focusedImage)
                            }
                            
                            ForEach(recentlyAddedLibrariesViewModels.sorted(by: { $0.key < $1.key }), id: \.key) {
                                HomeLibraryRecentlyAdded(viewModel: $1, focusedImage: $focusedImage)
                            }
                        }
                        .id(FocusSection.content)
                        .focused($focusedSection, equals: .content)
                        .focusSection()
                        
                        // Add safe area if required
                        .padding(.bottom, geoReader.safeAreaInsets.bottom)
                        .padding(.top, hasHero ? 0 : geoReader.safeAreaInsets.top)
                        
                        // Change the enlarged inage when the focues image changes
                        .onChange(of: focusedImage) { image in
                            guard let image = image else {
                                return
                            }
                            guard let id: String = {
                                let parts = image.components(separatedBy: "::")
                                if parts.count != 2 {
                                    return nil
                                }
                                
                                return parts[1]
                            }() else {
                                return
                            }
                            
                            if image.starts(with: "hero") {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    if focusedImage != image {
                                        return
                                    }
                                    
                                    let heroContent: [BaseItemDto] = viewModel.resumeItems + viewModel.nextUpItems
                                    enlargedItem = heroContent.filter {
                                        $0.id == id
                                    }.first
                                }
                            }
                        }
                        // Focus the right area of the screen when the user navigates
                        .onChange(of: focusedSection) { section in
                            guard let focusedSection = focusedSection else {
                                return
                            }
                            let focusedHero = focusedSection == .hero
                            
                            withAnimation(.easeInOut(duration: 0.25)) {
                                scrollView.scrollTo(FocusSection.hero, anchor: focusedHero ? .bottom : .top)
                                heroVisible = focusedHero
                            }
                        }
                    }
                }
                .background {
                    ZStack(alignment: .bottom) {
                        if heroVisible, let enlargedItem = enlargedItem {
                            // I know that .id prevents .animation form working but ImageView does not react to changes.
                            // The alternative would be to make ImageView react to changes (i can't be bothered) or to use AsyncImage but i think it is prefered to use the custom ImageView
                            ImageView(enlargedItem.landscapePosterImageSources(maxWidth: UIScreen.main.bounds.width, single: true))
                                .id(enlargedItem.id)
                                .animation(.easeInOut(duration: 0.25), value: enlargedItem)
                        }
                     
                        LinearGradient
                            .linearGradient(
                                Gradient(colors: [.black.opacity(0.75), .black.opacity(0)]),
                                startPoint: .bottom,
                                endPoint: .center)
                    }
                }
                .onAppear {
                    if viewModel.hasRecentlyAdded {
                        recentlyAddedViewModel = ItemTypeLibraryViewModel(itemTypes: [.movie, .series], filters: .init(sortOrder: [APISortOrder.descending.filter], sortBy: [SortBy.dateAdded.filter]), pageItemSize: 20)
                    }
                    
                    viewModel.libraries.forEach { library in
                        recentlyAddedLibrariesViewModels[library.id!] = LibraryViewModel(parent: library, type: .library, filters: .recent)
                    }
                }
                .ignoresSafeArea()
                .environment(\.safeAreaInsets, geoReader.safeAreaInsets)
            }
        }
        
        private enum FocusSection: Hashable {
            case spacer
            case hero
            case content
        }
    }
}

private struct SafeAreaInsetsKey: EnvironmentKey {
    static let defaultValue: EdgeInsets = .init(top: 0, leading: 25, bottom: 0, trailing: 25)
}
extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        get { self[SafeAreaInsetsKey.self] }
        set { self[SafeAreaInsetsKey.self] = newValue }
    }
}
