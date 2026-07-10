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

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @Environment(\.accessibilityReduceTransparency)
    private var reduceTransparency

    @Router
    private var router

    @StateObject
    private var viewModel = HomeViewModel()

    @State
    private var selectedHeroItem: BaseItemDto?

    @Default(.Customization.Home.showRecentlyAdded)
    private var showRecentlyAdded

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                if viewModel.spotlightItems.isNotEmpty {
                    CinematicRecommendedView(
                        items: viewModel.spotlightItems.elements,
                        selectionChanged: { selectedHeroItem = $0 }
                    )
                }

                if viewModel.resumeItems.isNotEmpty {
                    ContinueWatchingView(viewModel: viewModel)
                }

                NextUpView(viewModel: viewModel.nextUpViewModel)

                if showRecentlyAdded {
                    RecentlyAddedView(viewModel: viewModel.recentlyAddedViewModel)
                }

                ForEach(viewModel.libraries) { viewModel in
                    LatestInLibraryView(viewModel: viewModel)
                }
            }
            .background {
                scrollingBackdropBlur
            }
        }
    }

    private var scrollingBackdropBlur: some View {
        ZStack {
            if reduceTransparency {
                Color.black.opacity(0.9)
            } else {
                BlurView(style: .dark)
                    .opacity(0.72)
                Color.black.opacity(0.18)
            }
        }
        .mask {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: 620)

                LinearGradient(
                    colors: [.clear, .white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)

                Color.white
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var heroBackdrop: some View {
        if let selectedHeroItem {
            ZStack {
                ImageView(
                    selectedHeroItem.cinematicImageSources(maxWidth: 1920, quality: 90) +
                        selectedHeroItem.landscapeImageSources(maxWidth: 1920, quality: 90)
                )
                .image(selectedHeroItem.transform)
                .placeholder { _ in
                    Color.black
                }
                .failure {
                    Color.black
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

                Color.black.opacity(0.14)

                LinearGradient(
                    colors: [
                        .black.opacity(0.72),
                        .black.opacity(0.24),
                        .clear,
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )

                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.16),
                        .black.opacity(0.94),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .id(selectedHeroItem.hashValue)
            .transition(.opacity)
            .allowsHitTesting(false)
        }
    }

    var body: some View {
        ZStack {
            Color.black

            heroBackdrop

            switch viewModel.state {
            case .content:
                contentView
            case let .error(error):
                ErrorView(error: error)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: selectedHeroItem?.id)
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
