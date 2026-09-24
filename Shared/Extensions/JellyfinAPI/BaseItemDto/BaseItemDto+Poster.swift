//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Algorithms
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
            useParent: viewContext.contains(.isThumb) && environment.posterConfiguration.useSeriesLandscapeBackdrop,
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
            people?.first?.displayRole
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

    func imageSources(
        for displayType: PosterDisplayType,
        environment: Environment
    ) -> [ImageSource] {
        @ImageSourceBuilder
        var sources: [ImageSource] {
            let isLandscape = displayType == .landscape
            let preferThumb = isLandscape && environment.viewContext.contains(.isThumb)
            let inheritLandscape = !isLandscape || type != .episode || environment.useParent
            let isProgram = type == .program || type == .liveTvProgram || type == .tvProgram

            if isLandscape, environment.viewContext.contains(.isBackdrop) {
                if type == .episode {
                    imageSource(.backdrop, itemID: parentBackdropItemID, tag: parentBackdropImageTags?.first, environment: environment)
                }

                imageSource(.backdrop, itemID: id, environment: environment)
            }

            // Program squares represent the channel in the guide.
            if displayType == .square, isProgram {
                imageSource(.primary, itemID: channelID, tag: channelPrimaryImageTag, environment: environment)
            }

            if preferThumb {
                imageSource(.thumb, itemID: id, environment: environment)

                if inheritLandscape {
                    imageSource(.thumb, itemID: seriesID, tag: seriesThumbImageTag, environment: environment)
                    imageSource(.thumb, itemID: parentThumbItemID, tag: parentThumbImageTag, environment: environment)
                }
            }

            if isLandscape {
                let preferPrimary: Bool = if let primaryImageAspectRatio, primaryImageAspectRatio > 0 {
                    primaryImageAspectRatio >= 1.33
                } else {
                    switch type {
                    case .collectionFolder, .episode, .folder, .musicVideo, .userView, .video:
                        true
                    default:
                        false
                    }
                }

                if preferThumb || !preferPrimary {
                    imageSource(.backdrop, itemID: id, environment: environment)
                }

                if type == .season || (type == .episode && environment.useParent) {
                    imageSource(.backdrop, itemID: parentBackdropItemID, tag: parentBackdropImageTags?.first, environment: environment)
                }
            } else if type == .episode {
                // A portrait episode card uses its season/series poster when available.
                imageSource(.primary, itemID: parentPrimaryImageItemID, tag: parentPrimaryImageTag, environment: environment)
                imageSource(.primary, itemID: seriesID, tag: seriesPrimaryImageTag, environment: environment)
            }

            imageSource(.primary, itemID: id, environment: environment)

            // Never substitute a parent portrait for an episode's landscape still.
            if type != .episode || !isLandscape {
                imageSource(.primary, itemID: seriesID, tag: seriesPrimaryImageTag, environment: environment)
                imageSource(.primary, itemID: parentPrimaryImageItemID, tag: parentPrimaryImageTag, environment: environment)
            }

            imageSource(.primary, itemID: albumID, tag: albumPrimaryImageTag, environment: environment)

            if type == .season {
                imageSource(.thumb, itemID: id, environment: environment)
            }

            imageSource(.backdrop, itemID: id, environment: environment)
            imageSource(.thumb, itemID: id, environment: environment)

            if inheritLandscape {
                imageSource(.thumb, itemID: seriesID, tag: seriesThumbImageTag, environment: environment)
                imageSource(.thumb, itemID: parentThumbItemID, tag: parentThumbImageTag, environment: environment)
                imageSource(.backdrop, itemID: parentBackdropItemID, tag: parentBackdropImageTags?.first, environment: environment)
            }

            if isProgram {
                imageSource(.primary, itemID: channelID, tag: channelPrimaryImageTag, environment: environment)
            }
        }

        return Array(sources.uniqued())
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
                        .multilineTextAlignment(.leading)
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
