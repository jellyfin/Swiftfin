//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

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
        var useParent: Bool = false
        var viewContext: ViewContext = .init()

        static var `default`: Self {
            .init()
        }
    }

    func resolveEnvironment(_ environment: EnvironmentValues) -> Environment {
        let viewContext = environment.viewContext

        return .init(
            useParent: viewContext.contains(.isThumb) && environment.useSeriesLandscapeBackdrop,
            viewContext: viewContext
        )
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

    var systemImage: String {
        switch type {
        case .audio, .musicAlbum:
            "music.note"
        case .boxSet:
            "film.stack"
        case .channel, .tvChannel, .liveTvChannel, .program:
            "tv"
        case .episode, .movie, .season, .series, .video:
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
            imageSource(
                itemID: seriesID,
                .primary,
                tag: seriesPrimaryImageTag,
                environment: environment
            )
        case .boxSet, .channel, .liveTvChannel, .liveTvProgram, .movie, .musicArtist, .person, .program, .series, .tvChannel:
            imageSource(
                .primary,
                environment: environment
            )
        case .season:
            imageSource(
                .primary,
                environment: environment
            )

            imageSource(
                itemID: seriesID,
                .primary,
                tag: seriesPrimaryImageTag,
                environment: environment
            )
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
                    imageSource(
                        itemID: seriesID,
                        .thumb,
                        tag: seriesThumbImageTag,
                        environment: environment
                    )
                }

                imageSource(
                    .primary,
                    environment: environment
                )
            } else {
                imageSource(
                    .primary,
                    environment: environment
                )
            }
        case .collectionFolder, .folder, .musicVideo, .userView, .video:
            imageSource(
                .primary,
                environment: environment
            )
        case .season:
            if environment.viewContext.contains(.isThumb) {
                imageSource(
                    itemID: seriesID,
                    .thumb,
                    tag: seriesThumbImageTag,
                    environment: environment
                )
            }

            imageSource(
                itemID: seriesID,
                .backdrop,
                tag: parentBackdropImageTags?.first,
                environment: environment
            )
        default:
            if environment.viewContext.contains(.isThumb) {
                imageSource(
                    .thumb,
                    environment: environment
                )
            }

            imageSource(
                .backdrop,
                tag: backdropImageTags?.first,
                environment: environment
            )
        }
    }

    @ImageSourceBuilder
    func squareImageSources(
        environment: Environment
    ) -> [ImageSource] {
        switch type {
        case .audio:
            imageSource(
                .primary,
                environment: environment
            )

            imageSource(
                itemID: albumID,
                .primary,
                tag: albumPrimaryImageTag,
                environment: environment
            )
        case .channel, .musicAlbum, .tvChannel:
            imageSource(
                .primary,
                environment: environment
            )
        case .program:
            if let channelID {
                imageSource(
                    itemID: channelID,
                    .primary,
                    tag: channelPrimaryImageTag,
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
            Button(L10n.goToItem, systemImage: "info.circle") {
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

    let item: BaseItemDto

    var body: some View {
        switch item.type {
        case .episode:
            Label {
                if let seriesName = item.seriesName {
                    Text(seriesName)
                }
                if let indexLabel = item.seasonEpisodeLabel {
                    Text(indexLabel)
                }

                Text(item.displayTitle)
            }
        case .season:
            Label {
                Text(item.parentTitle ?? item.displayTitle)
                Text(item.displayTitle)
            }
        case .program:
            Label {
                Text(item.displayTitle)

                if let startDate = item.startDate {
                    ViewThatFits {
                        SeparatorHStack {
                            Text(String.hyphen)
                        } content: {
                            if !Calendar.current.isDateInToday(startDate) {
                                Text(startDate, format: .dateTime.weekday(.abbreviated).hour().minute())
                            } else {
                                Text(startDate, style: .time)
                            }

                            if let endDate = item.endDate {
                                Text(endDate, style: .time)
                            }
                        }

                        if !Calendar.current.isDateInToday(startDate) {
                            Text(startDate, format: .dateTime.weekday(.abbreviated).hour().minute())
                        } else {
                            Text(startDate, style: .time)
                        }
                    }
                } else {
                    Text(String.emptyRuntime)
                }

                if let channelName = item.channelName {
                    Text(channelName)
                }
            }
        case .video where item.extraType != nil:
            Label {
                Text(item.displayTitle)

                if let extraType = item.extraType, extraType != .unknown {
                    Text(extraType.displayTitle)
                }

                if let runtime = item.runtime {
                    Text(runtime, format: .runtime)
                }
            }
        default:
            Label {
                Text(item.displayTitle)

                if let subtitle = item.subtitle {
                    Text(subtitle)
                }
            }
        }
    }

    private struct Label: View {

        @Environment(\.posterDisplayType)
        private var posterDisplayType

        private let content: [AnyView]

        private var details: [AnyView] {
            let details = content.dropFirst()

            return posterDisplayType == .landscape ? details.asArray : details.prefix(1).asArray
        }

        init(@ArrayBuilder<any View> content: () -> [any View]) {
            self.content = content().map { AnyView($0) }
        }

        var body: some View {
            AlternateLayoutView(alignment: .topLeading) {
                VStack(spacing: 2) {
                    Text(String.space)
                    Text(String.space)
                }
                .font(.footnote)
                .frame(maxWidth: .infinity)
            } content: {
                VStack(alignment: .leading, spacing: 2) {
                    content.first
                        .font(.footnote)
                        .lineLimit(details.isEmpty ? 2 : 1, reservesSpace: true)

                    DotHStack {
                        ForEach(details.indices, id: \.self) { index in
                            details[index]
                                .layoutPriority(index == 0 ? 1 : 0)
                        }
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
