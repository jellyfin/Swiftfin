//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

// TODO: move popup to router
//       - or, make tab view environment object

// TODO: fix weird tvOS icon rendering
struct MainTabView: View {

    @Default(.Customization.latestInLibraryPosterType)
    private var latestInLibraryPosterType
    @Default(.Customization.showPosterLabels)
    private var showPosterLabels
    @Default(.Customization.Episodes.useSeriesLandscapeBackdrop)
    private var useSeriesLandscapeBackdrop

    #if os(iOS)
    @StateObject
    private var tabCoordinator = TabCoordinator {
        TabItem.home
        TabItem.search
        TabItem.media
    }
    #else
    @StateObject
    private var tabCoordinator = TabCoordinator {
        TabItem.home
        TabItem.library(
            title: L10n.tvShows,
            systemName: "tv",
            filters: .init(itemTypes: [.series])
        )
        TabItem.library(
            title: L10n.movies,
            systemName: "film",
            filters: .init(itemTypes: [.movie])
        )
        TabItem.search
        TabItem.media
        TabItem.settings
    }
    #endif

    @ViewBuilder
    var body: some View {
        TabView(selection: $tabCoordinator.selectedTabID) {
            ForEach(tabCoordinator.tabs, id: \.item.id) { tab in
                NavigationInjectionView(
                    coordinator: tab.coordinator
                ) {
                    tab.item.content
                }
                .environmentObject(tabCoordinator)
                .environment(\.tabItemSelected, tab.publisher)
                .tabItem {
                    Label(
                        tab.item.title,
                        systemImage: tab.item.systemImage
                    )
                    .labelStyle(tab.item.labelStyle)
                    .symbolRenderingMode(.monochrome)
                    .eraseToAnyView()
                }
                .tag(tab.item.id)
            }
        }
        .posterStyle(for: BaseItemDto.self) { item in

            @ViewBuilder
            func v() -> some View {
                if item.type == .program {
                    ProgramsView.ProgramButtonContent(
                        program: item
                    )
                } else {
                    TitleSubtitleContentView(
                        //                        title: item.displayTitle,
                        title: showPosterLabels ? item.displayTitle : nil,
                        subtitle: item.subtitle
                    )
                }
            }

            return .init(
                displayType: latestInLibraryPosterType,
                indicators: [],
                label: v(),
                overlay: EmptyView(),
                useParentImages: useSeriesLandscapeBackdrop,
                size: .medium
            )
        }
        .posterStyle(for: BaseItemPerson.self) { person in
            .init(
                displayType: .portrait,
                indicators: [],
                label: person.posterLabel,
                overlay: EmptyView(),
                useParentImages: false,
                size: .medium
            )
        }
    }
}

extension BaseItemDto {

    @ViewBuilder
    var posterLabel: some View {}
}

extension BaseItemPerson {

    var posterLabel: some View {
        TitleSubtitleContentView(
            title: displayTitle,
            subtitle: role
        )
    }
}
