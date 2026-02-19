//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import SwiftUI

struct HomeView: View {

    private enum HomeLook {
        static let topSpacing: CGFloat = 56
        static let sectionSpacing: CGFloat = 30

        static var backgroundGradient: LinearGradient {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.06, blue: 0.12),
                    Color(red: 0.04, green: 0.10, blue: 0.19),
                    Color(red: 0.08, green: 0.05, blue: 0.12),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    @Router
    private var router

    @StateObject
    private var viewModel = HomeViewModel()

    @Default(.Customization.Home.showRecentlyAdded)
    private var showRecentlyAdded

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HomeLook.sectionSpacing) {

                if viewModel.resumeItems.isNotEmpty {
                    CinematicResumeView(viewModel: viewModel)

                    NextUpView(viewModel: viewModel.nextUpViewModel)

                    if showRecentlyAdded {
                        RecentlyAddedView(viewModel: viewModel.recentlyAddedViewModel)
                    }
                } else {
                    if showRecentlyAdded {
                        CinematicRecentlyAddedView(viewModel: viewModel.recentlyAddedViewModel)
                    }

                    NextUpView(viewModel: viewModel.nextUpViewModel)
                        .safeAreaPadding(.top, 150)
                }

                ForEach(viewModel.libraries) { viewModel in
                    LatestInLibraryView(viewModel: viewModel)
                }
            }
            .safeAreaPadding(.top, HomeLook.topSpacing)
        }
    }

    var body: some View {
        ZStack {
            HomeLook.backgroundGradient

            GeometryReader { proxy in
                ZStack {
                    Circle()
                        .fill(Color(red: 0.98, green: 0.57, blue: 0.20).opacity(0.20))
                        .frame(width: proxy.size.width * 0.50)
                        .blur(radius: 90)
                        .position(x: proxy.size.width * 0.80, y: proxy.size.height * 0.16)

                    Circle()
                        .fill(Color(red: 0.32, green: 0.76, blue: 0.97).opacity(0.22))
                        .frame(width: proxy.size.width * 0.64)
                        .blur(radius: 110)
                        .position(x: proxy.size.width * 0.08, y: proxy.size.height * 0.74)
                }
            }
            .allowsHitTesting(false)

            switch viewModel.state {
            case .content:
                contentView
            case let .error(error):
                ErrorView(error: error)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .refreshable {
            viewModel.send(.refresh)
        }
        .onFirstAppear {
            viewModel.send(.refresh)
        }
        .ignoresSafeArea()
        .sinceLastDisappear { interval in
            if interval > 60 || viewModel.notificationsReceived.contains(.itemMetadataDidChange) {
                viewModel.send(.backgroundRefresh)
                viewModel.notificationsReceived.remove(.itemMetadataDidChange)
            }
        }
    }
}
