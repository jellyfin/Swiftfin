//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import FactoryKit
import Foundation
import Get
import JellyfinAPI
import SwiftUI

extension BaseItemDto: Poster {

    struct Environment: WithDefaultValue, WithImageSourceOptions, WithViewContext {

        var maxWidth: CGFloat?
        var maxHeight: CGFloat?
        var quality: Int?
        var useParent: Bool = Defaults[.Customization.Episodes.useSeriesLandscapeBackdrop]
        var viewContext: ViewContext = .init()

        static var `default`: Self {
            .init()
        }
    }

    var preferredPosterDisplayType: PosterDisplayType {
        type?.preferredPosterDisplayType ?? .portrait
    }

    var subtitle: String? {
        switch type {
        case .episode:
            seasonEpisodeLabel
        case .person:
            people?.first?.firstRole
        case .video:
            extraType?.displayTitle
        default:
            nil
        }
    }

    var showTitle: Bool {
        switch type {
        case .episode, .series, .movie, .boxSet, .collectionFolder:
            Defaults[.Customization.showPosterLabels]
        default:
            true
        }
    }

    var systemImage: String {
        switch type {
        case .audio, .musicAlbum:
            "music.note"
        case .boxSet:
            "film.stack"
        case .channel, .tvChannel, .liveTvChannel, .program:
            "tv"
        case .episode, .movie, .series, .video:
            "film"
        case .collectionFolder, .folder, .userView:
            "folder.fill"
        case .musicVideo:
            "music.note.tv.fill"
        case .person:
            "person.fill"
        default:
            "circle"
        }
    }

    @ViewBuilder
    var posterLabel: some View {
        BaseItemDtoPosterLabel(item: self)
    }

    @ViewBuilder
    var posterContextMenu: some View {
        BaseItemDtoPosterContextMenu(item: self)
    }

    @ViewBuilder
    func posterOverlay(for displayType: PosterDisplayType) -> some View {
        ZStack {
            PosterSelectionOverlay()

            PosterIndicatorsOverlay(
                item: self,
                indicators: Defaults[.Customization.Indicators.enabled],
                posterDisplayType: displayType
            )
        }
    }

    @ImageSourceBuilder
    func portraitImageSources(
        environment: Environment
    ) -> [ImageSource] {
        switch type {
        case .episode:
            imageSource(itemID: seasonID, .primary, environment: environment)
        case .boxSet, .channel, .liveTvChannel, .movie, .musicArtist, .person, .series, .tvChannel:
            imageSource(.primary, environment: environment)
        default:
            []
        }
    }

    @ImageSourceBuilder
    func landscapeImageSources(
        environment: Environment
    ) -> [ImageSource] {
        switch type {
        case .episode:
            if environment.useParent {
                if environment.viewContext.contains(.isThumb) {
                    imageSource(itemID: seriesID, .thumb, environment: environment)
                }
                imageSource(itemID: seriesID, .backdrop, environment: environment)
                imageSource(.primary, environment: environment)
            } else {
                imageSource(.primary, environment: environment)
            }
        case .collectionFolder, .folder, .liveTvProgram, .musicVideo, .program, .userView, .video:
            imageSource(.primary, environment: environment)
        default:
            if environment.viewContext.contains(.isThumb) {
                imageSource(.thumb, environment: environment)
            }
            imageSource(.backdrop, environment: environment)
        }
    }

    @ImageSourceBuilder
    func squareImageSources(
        environment: Environment
    ) -> [ImageSource] {
        switch type {
        case .audio:
            imageSource(.primary, environment: environment)
            imageSource(
                itemID: albumID,
                .primary,
                environment: environment
            )
        case .channel, .musicAlbum, .tvChannel:
            imageSource(.primary, environment: environment)
        case .program:
            if let channelID {
                imageSource(
                    itemID: channelID,
                    .primary,
                    environment: environment
                )
            }
        default:
            []
        }
    }

    @ViewBuilder
    func transform(image: Image, displayType: PosterDisplayType) -> some View {
        switch type {
        case .channel, .tvChannel:
            ContainerRelativeView(ratio: 0.95) {
                image
                    .aspectRatio(contentMode: .fit)
            }
        case .program:
            if displayType == .square {
                ContainerRelativeView(ratio: 0.95) {
                    image
                        .aspectRatio(contentMode: .fit)
                }
            } else {
                image
                    .aspectRatio(contentMode: .fill)
            }
        default:
            image
                .aspectRatio(contentMode: .fill)
        }
    }
}

private struct BaseItemDtoPosterContextMenu: View {

    @Router
    private var router

    @State
    private var item: BaseItemDto

    init(item: BaseItemDto) {
        self.item = item
    }

    private var isFavorite: Bool {
        item.userData?.isFavorite == true
    }

    private var isPlayed: Bool {
        item.userData?.isPlayed == true
    }

    var body: some View {
        if let itemID = item.id {
            Button(L10n.goToItem, systemImage: "arrow.forward.circle") {
                router.route(to: .item(id: itemID))
            }
        }

        if item.type == .episode, let seriesID = item.seriesID {
            Button(L10n.goToSeries, systemImage: "tv") {
                router.route(to: .item(id: seriesID))
            }
        }

        if item.canBePlayed {
            Button(isPlayed ? L10n.markAsUnplayed : L10n.markAsPlayed, systemImage: isPlayed ? "circle" : "checkmark.circle") {
                Task {
                    await toggleIsPlayed()
                }
            }
        }

        if item.id != nil {
            Button(isFavorite ? L10n.removeFromFavorites : L10n.addToFavorites, systemImage: isFavorite ? "heart.slash" : "heart") {
                Task {
                    await toggleIsFavorite()
                }
            }
        }
    }

    @MainActor
    private func toggleIsPlayed() async {
        let beforeIsPlayed = item.userData?.isPlayed ?? false

        item.userData?.isPlayed = !beforeIsPlayed
        do {
            try await setIsPlayed(!beforeIsPlayed)
        } catch {
            item.userData?.isPlayed = beforeIsPlayed
        }
    }

    @MainActor
    private func toggleIsFavorite() async {
        let beforeIsFavorite = item.userData?.isFavorite ?? false

        item.userData?.isFavorite = !beforeIsFavorite
        do {
            try await setIsFavorite(!beforeIsFavorite)
        } catch {
            item.userData?.isFavorite = beforeIsFavorite
        }
    }

    private func setIsPlayed(_ isPlayed: Bool) async throws {
        guard let itemID = item.id,
              let userSession = Container.shared.currentUserSession()
        else { return }

        let request: Request<UserItemDataDto> = if isPlayed {
            Paths.markPlayedItem(
                itemID: itemID,
                userID: userSession.user.id
            )
        } else {
            Paths.markUnplayedItem(
                itemID: itemID,
                userID: userSession.user.id
            )
        }

        let response = try await userSession.client.send(request)
        item.userData = response.value
        Notifications[.itemUserDataDidChange].post(response.value)
        Notifications[.itemShouldRefreshMetadata].post(itemID)
    }

    private func setIsFavorite(_ isFavorite: Bool) async throws {
        guard let itemID = item.id,
              let userSession = Container.shared.currentUserSession()
        else { return }

        let request: Request<UserItemDataDto> = if isFavorite {
            Paths.markFavoriteItem(
                itemID: itemID,
                userID: userSession.user.id
            )
        } else {
            Paths.unmarkFavoriteItem(
                itemID: itemID,
                userID: userSession.user.id
            )
        }

        let response = try await userSession.client.send(request)
        item.userData = response.value
        Notifications[.itemUserDataDidChange].post(response.value)
        Notifications[.itemShouldRefreshMetadata].post(itemID)
    }
}

private struct BaseItemDtoPosterLabel: View {

    @Default(.Customization.showPosterLabels)
    private var showPosterLabels

    #if os(iOS)
    @Default(.Customization.Episodes.useSeriesLandscapeBackdrop)
    private var useSeriesLandscapeBackdrop
    #endif

    let item: BaseItemDto

    var body: some View {
        switch item.type {
        case .program:
            programLabel
        case .episode:
            episodeLabel
        default:
            titleSubtitleLabel
        }
    }

    private var titleSubtitleLabel: some View {
        VStack(alignment: .leading, spacing: 0) {
            if item.showTitle {
                Text(item.displayTitle)
                    .font(.footnote)
                    .foregroundColor(.primary)
                    .accessibilityLabel(item.displayTitle)
                    .lineLimit(1, reservesSpace: true)
            }

            Text(item.subtitle ?? " ")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .lineLimit(1, reservesSpace: true)
        }
    }

    private var episodeLabel: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showPosterLabels, let seriesName = item.seriesName {
                Text(seriesName)
                    .font(.footnote.weight(.regular))
                    .foregroundColor(.primary)
                    .lineLimit(1, reservesSpace: true)
            }

            DotHStack {
                Text(item.seasonEpisodeLabel ?? .emptyDash)

                if showsEpisodeTitle {
                    Text(item.displayTitle)
                } else if let seriesName = item.seriesName {
                    Text(seriesName)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(1)
        }
    }

    private var showsEpisodeTitle: Bool {
        #if os(iOS)
        showPosterLabels || useSeriesLandscapeBackdrop
        #else
        showPosterLabels
        #endif
    }

    private var programLabel: some View {
        VStack(alignment: .leading) {
            Text(item.channelName ?? .emptyDash)
                .font(.footnote.weight(.semibold))
                .foregroundColor(.primary)
                .lineLimit(1, reservesSpace: true)

            Text(item.displayTitle)
                .font(.footnote.weight(.regular))
                .foregroundColor(.primary)
                .lineLimit(1, reservesSpace: true)

            HStack(spacing: 2) {
                if let startDate = item.startDate {
                    Text(startDate, style: .time)
                } else {
                    Text(String.emptyDash)
                }

                Text(String.hyphen)

                if let endDate = item.endDate {
                    Text(endDate, style: .time)
                } else {
                    Text(String.emptyDash)
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
}
