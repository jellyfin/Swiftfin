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

extension SeasonItemView {

    struct ContentView: View {

        @EnvironmentObject
        var itemRouter: ItemCoordinator.Router
        @ObservedObject
        var viewModel: SeasonItemViewModel

        var body: some View {
            VStack(spacing: 10) {

                HStack(alignment: .bottom) {
                    ImageView(viewModel.item.imageSource(.primary, maxWidth: 150))
                        .portraitPoster(width: 150)

                    VStack(alignment: .leading) {
                        Text(viewModel.item.seriesName ?? "--")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                            .foregroundColor(.secondary)

                        Text(viewModel.item.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal)
                    }

                    Spacer()
                }
                .padding(.horizontal)

                // MARK: Overview

                if let itemOverview = viewModel.item.overview {
                    HStack {
                        TruncatedTextView(
                            itemOverview,
                            lineLimit: 5,
                            font: UIFont.preferredFont(forTextStyle: .footnote)
                        ) {
                            itemRouter.route(to: \.itemOverview, viewModel.item)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top)
                        .padding(.horizontal)

                        Spacer(minLength: 0)
                    }
                }

                EpisodesRowView(viewModel: viewModel, singleSeason: true)

                // MARK: Genres

                if let genres = viewModel.item.genreItems, !genres.isEmpty {
                    PillHStack(
                        title: L10n.genres,
                        items: genres,
                        selectedAction: { genre in
                            itemRouter.route(to: \.library, (viewModel: .init(genre: genre), title: genre.title))
                        }
                    )
                    .padding(.bottom)
                }

                // MARK: Studios

                if let studios = viewModel.item.studios {
                    PillHStack(
                        title: L10n.studios,
                        items: studios
                    ) { studio in
                        itemRouter.route(to: \.library, (viewModel: .init(studio: studio), title: studio.name ?? ""))
                    }
                    .padding(.bottom)
                }

                // MARK: Cast and Crew

                if let castAndCrew = viewModel.item.people?.filter { BaseItemPerson.DisplayedType.allCasesRaw.contains($0.type ?? "") },
                   !castAndCrew.isEmpty {
                       PortraitPosterHStack(
                           title: L10n.castAndCrew,
                           items: castAndCrew
                       ) { person in
                           itemRouter.route(to: \.library, (viewModel: .init(person: person), title: person.title))
                       }
                   }

                // MARK: Details

                HStack {
                    ListDetailsView(title: L10n.information, items: viewModel.item.createInformationItems())

                    Spacer(minLength: 0)
                }
                .padding(.horizontal)
            }
        }
    }
}
