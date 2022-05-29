//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct iPadOSSeriesItemView: View {

    @EnvironmentObject
    var itemRouter: ItemCoordinator.Router
    @EnvironmentObject
    private var viewModel: SeriesItemViewModel
    @Default(.showCastAndCrew)
    var showCastAndCrew

    // MARK: portraitHeaderView

    @ViewBuilder
    var portraitHeaderView: some View {
        ImageView(viewModel.item.getBackdropImage(maxWidth: Int(UIScreen.main.bounds.width)),
                  blurHash: viewModel.item.getBackdropImageBlurHash())
    }

    // MARK: portraitStaticOverlayView

    @ViewBuilder
    var portraitStaticOverlayView: some View {
        HStack {
            
            VStack {
                Text(viewModel.item.name ?? "--")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            VStack {
                Button {
                    if let selectedVideoPlayerViewModel = viewModel.selectedVideoPlayerViewModel {
                        itemRouter.route(to: \.videoPlayer, selectedVideoPlayerViewModel)
                    } else {
                        LogManager.log.error("Attempted to play item but no playback information available")
                    }
                } label: {
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color(UIColor.systemPurple))
                            .frame(maxWidth: 250)
                            .frame(height: 50)
                            .cornerRadius(10)
                        
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.system(size: 20))
                            Text(viewModel.playButtonText())
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(viewModel.playButtonItem == nil ? Color(UIColor.secondaryLabel) : Color.white)
                    }
                }
                .contextMenu {
                    if viewModel.playButtonItem != nil, viewModel.item.userData?.playbackPositionTicks ?? 0 > 0 {
                        Button {
                            if let selectedVideoPlayerViewModel = viewModel.selectedVideoPlayerViewModel {
                                selectedVideoPlayerViewModel.injectCustomValues(startFromBeginning: true)
                                itemRouter.route(to: \.videoPlayer, selectedVideoPlayerViewModel)
                            } else {
                                LogManager.log.error("Attempted to play item but no playback information available")
                            }
                        } label: {
                            Label(L10n.playFromBeginning, systemImage: "gobackward")
                        }
                    }
                }
                
                HStack {
                    Button {
                        print("Button")
                    } label: {
                        Rectangle()
                            .foregroundColor(.red)
                            .frame(height: 50)
                            .cornerRadius(10)
                    }
                    
                    Button {
                        print("Button")
                    } label: {
                        Rectangle()
                            .foregroundColor(.red)
                            .frame(height: 50)
                            .cornerRadius(10)
                    }

                    Button {
                        print("Button")
                    } label: {
                        Rectangle()
                            .foregroundColor(.red)
                            .frame(height: 50)
                            .cornerRadius(10)
                    }
                }
            }
            .frame(maxWidth: 250)
        }
        .padding()
        .padding(.top, 100)
        .background {
            BlurView()
                .mask {
                    LinearGradient(gradient: Gradient(stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white, location: 0.2),
                        .init(color: .white.opacity(0), location: 1)
                    ]), startPoint: .bottom, endPoint: .top)
                }
        }
    }

    // MARK: innerBody

    var innerBody: some View {
        VStack(alignment: .leading) {

            // MARK: Seasons

            EpisodesRowView(viewModel: viewModel)

            // MARK: Genres

            if let genres = viewModel.item.genreItems, !genres.isEmpty {
                PillHStackView(title: L10n.genres,
                               items: genres,
                               selectedAction: { genre in
                                   itemRouter.route(to: \.library, (viewModel: .init(genre: genre), title: genre.title))
                               })
                               .padding(.bottom)
            }

            // MARK: Studios

            if let studios = viewModel.item.studios {
                PillHStackView(title: L10n.studios,
                               items: studios) { studio in
                    itemRouter.route(to: \.library, (viewModel: .init(studio: studio), title: studio.name ?? ""))
                }
                .padding(.bottom)
            }

            // MARK: Episodes

            if showCastAndCrew {
                if let castAndCrew = viewModel.item.people, !castAndCrew.isEmpty {
                    PortraitImageHStackView(items: castAndCrew.filter { BaseItemPerson.DisplayedType.allCasesRaw.contains($0.type ?? "") },
                                            topBarView: {
                                                L10n.castAndCrew.text
                                                    .fontWeight(.semibold)
                                                    .padding(.bottom)
                                                    .padding(.horizontal)
                                                    .accessibility(addTraits: [.isHeader])
                                            },
                                            selectedAction: { person in
                                                itemRouter.route(to: \.library, (viewModel: .init(person: person), title: person.title))
                                            })
                }
            }

            // MARK: Recommended

            if !viewModel.similarItems.isEmpty {
                PortraitImageHStackView(items: viewModel.similarItems,
                                        topBarView: {
                                            L10n.recommended.text
                                                .fontWeight(.semibold)
                                                .padding(.bottom)
                                                .padding(.horizontal)
                                                .accessibility(addTraits: [.isHeader])
                                        },
                                        selectedAction: { item in
                                            itemRouter.route(to: \.item, item)
                                        })
            }

            // MARK: Details
            
            ListDetailsView(title: "Information", items: [
                .init(title: "Runtime", content: viewModel.getRunYears()),
                .init(title: "Rated", content: viewModel.item.officialRating ?? "--")
            ])
            .padding()
        }
    }

    var body: some View {
                ParallaxHeaderScrollView(header: portraitHeaderView,
                                         staticOverlayView: portraitStaticOverlayView,
                                         overlayAlignment: .bottomLeading,
                                         headerHeight: UIScreen.main.bounds.height * 0.8) {
//                    VStack {
//                        Spacer()
//                            .frame(height: 70)

                        innerBody
//                    }
                }
    }
}
