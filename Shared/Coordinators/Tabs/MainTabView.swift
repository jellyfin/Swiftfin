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

struct MainTabView: View {

    @Default(.Customization.showPosterLabels)
    private var showPosterLabels
    @Default(.Customization.Episodes.useSeriesLandscapeBackdrop)
    private var useSeriesLandscapeBackdrop

    @Default(.Customization.Library._libraryStyle)
    private var defaultLibraryStyle

    #if os(iOS)
    @StateObject
    private var tabCoordinator = TabCoordinator {
        TabItemSetting.contentGroup(.default)
        TabItemSetting.search
        TabItemSetting.media
        TabItemSetting.liveTV
//        TabItemSetting.contentGroup(StoredValues[.User.customContentGroup(id: "asdf")])
    }
    #else
    @StateObject
    private var tabCoordinator = TabCoordinator {
        TabItem.contentGroup(provider: DefaultContentGroupProvider())
        TabItem.library(
            title: L10n.tvShowsCapitalized,
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

    var body: some View {
        TabView(selection: $tabCoordinator.selectedTabID) {
            ForEach(tabCoordinator.tabs, id: \.item.id) { tab in
                NavigationInjectionView(
                    coordinator: tab.coordinator
                ) {
                    tab.item.content
                    #if os(iOS)
                        .topBarTrailing {
                            if tab.item.id != "settings" {
                                SettingsBarButton()
                            }
                        }
                    #endif
                }
                .environmentObject(tabCoordinator)
                .environment(\.tabItemSelected, tab.publisher)
                .tabItem {
                    Label(
                        tab.item.displayTitle,
                        systemImage: tab.item.systemImage
                    )
                    .symbolRenderingMode(.monochrome)
                }
                .tag(tab.item.id)
            }
        }
//        .backport
//        .tabViewStyle(.sidebarAdaptable)
        .contextMenu(for: BaseItemDto.self) { item in
            // TODO: get view context environment for thumbnail vs backdrop

            if item.type == .episode {
                WithRouter { router in
                    Button("Go to Episode", systemImage: "info.circle") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            router.route(to: .item(item: item))
                        }
                    }
                }

                if let seriesID = item.seriesID {
                    WithRouter { router in
                        Button("Go to Show", systemImage: "info.circle") {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                router.route(
                                    to: .item(
                                        displayTitle: item.displayTitle,
                                        id: seriesID
                                    )
                                )
                            }
                        }
                    }
                }
            } else {
                WithRouter { router in
                    Button("Go to Item", systemImage: "info.circle") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            router.route(to: .item(item: item))
                        }
                    }
                }
            }
        }
        .libraryStyle(for: BaseItemDto.self) { _, _ in
            (defaultLibraryStyle, $defaultLibraryStyle)
        }
        .libraryStyle(for: ChannelProgram.self) { _, _ in
            (defaultLibraryStyle, $defaultLibraryStyle)
        }
        .customEnvironment(
            for: BaseItemDto.self,
            value: .init(useParent: useSeriesLandscapeBackdrop)
        )
    }
}

// struct ProgramButtonContent: View {
//
//    let program: BaseItemDto
//
//    var body: some View {
//        VStack(alignment: .leading) {
//
//            Text(program.channelName ?? .emptyDash)
//                .font(.footnote.weight(.semibold))
//                .foregroundColor(.primary)
//                .lineLimit(1, reservesSpace: true)
//
//            Text(program.displayTitle)
//                .font(.footnote.weight(.regular))
//                .foregroundColor(.primary)
//                .lineLimit(1, reservesSpace: true)
//
////            HStack(spacing: 2) {
////                if let startDate = program.startDate {
////                    Text(startDate, style: .time)
////                } else {
////                    Text(String.emptyDash)
////                }
////
////                Text("-")
////
////                if let endDate = program.endDate {
////                    Text(endDate, style: .time)
////                } else {
////                    Text(String.emptyDash)
////                }
////            }
////            .font(.footnote)
////            .foregroundStyle(.secondary)
//        }
//    }
// }
