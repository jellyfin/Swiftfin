//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension EpisodeItemView {

    struct ContentView: View {

        @ObservedObject
        var viewModel: EpisodeItemViewModel
        @State
        var scrollViewProxy: ScrollViewProxy

        @EnvironmentObject
        private var itemRouter: ItemCoordinator.Router
        @ObservedObject
        private var focusGuide = FocusGuide()
        @State
        private var showName: Bool = false

        var body: some View {
            VStack {
                Self.EpisodeCinematicHeaderView(viewModel: viewModel)
                    .focusGuide(focusGuide, tag: "mediaButtons", bottom: "recommended")
                    .frame(height: UIScreen.main.bounds.height - 150)
                    .padding(.bottom, 50)

                VStack(spacing: 0) {

                    Color.clear
                        .frame(height: 0.5)
                        .id("topContentDivider")

                    if showName {
                        Text(viewModel.item.displayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .foregroundColor(.white)
                    }

                    PortraitPosterHStack(
                        title: L10n.recommended,
                        items: viewModel.similarItems
                    ) { item in
                        itemRouter.route(to: \.item, item)
                    }
                    .focusGuide(focusGuide, tag: "recommended", top: "mediaButtons", bottom: "about")

                    ItemView.AboutView(viewModel: viewModel)
                        .focusGuide(focusGuide, tag: "about", top: "recommended")

                    Spacer()
                }
                .frame(minHeight: UIScreen.main.bounds.height)
            }
            .background {
                BlurView()
                    .mask {
                        VStack(spacing: 0) {
                            LinearGradient(gradient: Gradient(stops: [
                                .init(color: .white, location: 0),
                                .init(color: .white.opacity(0.5), location: 0.6),
                                .init(color: .white.opacity(0), location: 1),
                            ]), startPoint: .bottom, endPoint: .top)
                                .frame(height: UIScreen.main.bounds.height - 150)

                            Color.white
                        }
                    }
            }
            .onChange(of: focusGuide.focusedTag) { newTag in
                if newTag == "recommended" && !showName {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.easeIn(duration: 0.35)) {
                            scrollViewProxy.scrollTo("topContentDivider")
                        }
                    }
                    withAnimation {
                        self.showName = true
                    }
                } else if newTag == "mediaButtons" {
                    withAnimation {
                        self.showName = false
                    }
                }
            }
        }
    }
}

extension EpisodeItemView.ContentView {

    struct EpisodeCinematicHeaderView: View {

        enum CinematicHeaderFocusLayer: Hashable {
            case top
            case playButton
        }

        @EnvironmentObject
        private var itemRouter: ItemCoordinator.Router
        @FocusState
        private var focusedLayer: CinematicHeaderFocusLayer?
        @EnvironmentObject
        private var focusGuide: FocusGuide
        @ObservedObject
        var viewModel: EpisodeItemViewModel

        var body: some View {
            VStack(alignment: .leading) {

                Color.clear
                    .focusable()
                    .focused($focusedLayer, equals: .top)

                HStack(alignment: .bottom) {

                    VStack(alignment: .leading, spacing: 20) {

                        if let seriesName = viewModel.item.seriesName {
                            Text(seriesName)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }

                        Text(viewModel.item.displayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.white)

                        if let overview = viewModel.item.overview {
                            Text(overview)
                                .font(.subheadline)
                                .lineLimit(4)
                        } else {
                            L10n.noOverviewAvailable.text
                        }

                        HStack {
                            DotHStack {
                                if let premiereYear = viewModel.item.premiereDateYear {
                                    premiereYear.text
                                }

                                if let playButtonitem = viewModel.playButtonItem, let runtime = playButtonitem.getItemRuntime() {
                                    runtime.text
                                }
                            }
                            .font(.caption)
                            .foregroundColor(Color(UIColor.lightGray))

                            ItemView.AttributesHStack(viewModel: viewModel)
                        }
                    }

                    Spacer()

                    VStack {
                        ItemView.PlayButton(viewModel: viewModel)
                            .focused($focusedLayer, equals: .playButton)

                        ItemView.ActionButtonHStack(viewModel: viewModel)
                            .frame(width: 400)
                    }
                    .frame(width: 450)
                    .padding(.leading, 150)
                }
            }
            .padding(.horizontal, 50)
            .onChange(of: focusedLayer) { layer in
                if layer == .top {
                    focusedLayer = .playButton
                }
            }
        }
    }
}
