//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Introspect
import JellyfinAPI
import SwiftUI

struct SeriesEpisodeView: View {
    
    @ObservedObject
    var viewModel: SeriesItemViewModel
    @State
    var currentLayerTransition: FocusedLayerTransition?
    
    @FocusState
    var isFocused: Bool
    @FocusState
    var focusedLayer: FocusedLayer?
    
    @Binding
    var seriesItemTransitionBinding: SeriesItemView.FocusTransition?
    
    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: 1)
                .focusable()
                .focused($focusedLayer, equals: .topDivider)
            
            SeasonsHStack(viewModel: viewModel,
                          transitionBinding: $currentLayerTransition)
                .focused($focusedLayer, equals: .seasons)
            
            Color.clear
                .frame(height: 1)
                .focusable()
                .focused($focusedLayer, equals: .middleDivider)
            
            EpisodesHStack(viewModel: viewModel,
                           transitionBinding: $currentLayerTransition)
                .focused($focusedLayer, equals: .episodes)
            
            Color.clear
                .frame(height: 1)
                .focusable()
                .focused($focusedLayer, equals: .bottomDivider)
                .id("body")
        }
        .focused($isFocused)
        .onChange(of: focusedLayer) { [focusedLayer] newLayer in
            if newLayer == .middleDivider && focusedLayer == .seasons {
                currentLayerTransition = .leavingSeasonsToEpisodes
            } else if newLayer == .middleDivider && focusedLayer == .episodes {
                currentLayerTransition = .leavingEpisodesToSeasons
            } else if newLayer == .topDivider && focusedLayer == nil {
                currentLayerTransition = .enteringSectionSeasons
            } else if newLayer == .bottomDivider && focusedLayer == nil {
                currentLayerTransition = .enteringSectionEpisodes
            } else if newLayer == .topDivider && focusedLayer == .seasons {
                currentLayerTransition = .exitingSectionTop
                seriesItemTransitionBinding = .leavingSeasonsTop
            } else if newLayer == .bottomDivider && focusedLayer == .episodes {
                currentLayerTransition = .exitingSectionBottom
                seriesItemTransitionBinding = .leavingSeasonsBottom
            }
        }
        .onChange(of: seriesItemTransitionBinding) { newValue in
            if newValue == .leavingActionBottom {
                currentLayerTransition = .enteringSectionSeasons
                print("SeriesEpisodeView grabbed leavingActionBottom")
            }
        }
    }
}

extension SeriesEpisodeView {
    
    struct SeasonsHStack: View {
        
        @ObservedObject
        var viewModel: SeriesItemViewModel
        
        // MARK: Focus
        
        @FocusState
        var focusedSeason: BaseItemDto?
        
        // MARK: Transition
        
        @Binding
        var transitionBinding: FocusedLayerTransition?
        
        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(viewModel.sortedSeasons, id: \.self) { season in
                        Button {
                            print(season.displayName)
                        } label: {
                            Text(season.displayName)
                                .fontWeight(.semibold)
                                .fixedSize()
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .if(viewModel.selectedSeason == season) { text in
                                    text
                                        .background(Color.white)
                                        .foregroundColor(.black)
                                }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .background(Color.clear)
                        .id(season)
                        .focused($focusedSeason, equals: season)
                    }
                }
                .frame(height: 70)
                .padding(.horizontal, 50)
                .padding(.vertical)
                .padding(.bottom)
            }
            .onChange(of: focusedSeason) { season in
                guard let season = season else { return }
                viewModel.select(season: season)
            }
            .onChange(of: transitionBinding) { transition in
                if transition == .leavingEpisodesToSeasons || transition == .enteringSectionSeasons {
                    focusedSeason = viewModel.selectedSeason
                }
            }
        }
    }
}

extension SeriesEpisodeView {
    
    struct EpisodesHStack: View {
        
        @ObservedObject
        var viewModel: SeriesItemViewModel
        
        // MARK: Focus
        
        @FocusState
        var focusedEpisode: BaseItemDto?
        @State
        var lastFocusedEpisode: BaseItemDto?
        @State
        var wrappedScrollView: UIScrollView?
        
        // MARK: Transition
        
        @Binding
        var transitionBinding: FocusedLayerTransition?
        
        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top) {
                    if let currentEpisodes = viewModel.currentEpisodes, !currentEpisodes.isEmpty {
                        ForEach(currentEpisodes, id: \.self) { episode in
                            EpisodeRowCard(episode: episode)
                                .focused($focusedEpisode, equals: episode)
                        }
                    } else {
                        ForEach(0..<10) { _ in
                            EpisodeRowCard(episode: .init(name: "Test",
                                                          overview: String(repeating: "a", count: Int.random(in: 0..<50)),
                                                          indexNumber: 20))
                            .redacted(reason: .placeholder)
                        }
                    }
                }
                .padding(.horizontal, 50)
                .padding(.vertical)
            }
            .animation(.linear(duration: 0.1), value: viewModel.selectedSeason)
            .transition(.opacity)
            .introspectScrollView { scrollView in
                wrappedScrollView = scrollView
            }
            .onChange(of: viewModel.selectedSeason) { season in
                lastFocusedEpisode = viewModel.currentEpisodes?.first
                wrappedScrollView?.scrollToTop(animated: false)
            }
            .onChange(of: focusedEpisode) { episode in
                guard let episode = episode else { return }
                lastFocusedEpisode = episode
            }
            .onChange(of: transitionBinding) { transition in
                if transition == .leavingSeasonsToEpisodes || transition == .enteringSectionEpisodes {
                    if lastFocusedEpisode == nil {
                        lastFocusedEpisode = viewModel.currentEpisodes?.first
                    }
                    focusedEpisode = lastFocusedEpisode
                }
            }
        }
    }
}

extension SeriesEpisodeView {
    enum FocusedLayerTransition: Hashable {
        case leavingSeasonsToEpisodes
        case leavingEpisodesToSeasons
        case enteringSectionSeasons
        case enteringSectionEpisodes
        case exitingSectionTop
        case exitingSectionBottom
    }

    enum FocusedLayer: Hashable {
        case topDivider
        case seasons
        case middleDivider
        case episodes
        case bottomDivider
    }
}
