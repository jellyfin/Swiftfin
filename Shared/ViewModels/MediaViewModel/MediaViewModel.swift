//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import JellyfinAPI
import Nuke
import OrderedCollections

#if os(tvOS)
extension Container {

    /// A single shared, session-scoped `MediaViewModel`. Sharing it lets the app **prefetch** the
    /// Media tile backdrops in the background at launch (see `HomeView`) into the SAME instance the
    /// tab later displays — so the first visit shows the artwork instantly instead of fetching +
    /// blurring in. Mirrors `requestsViewModel` / `searchViewModel`.
    var mediaViewModel: Factory<MediaViewModel> {
        self { @MainActor in MediaViewModel() }
            .scope(.session)
    }
}
#endif

@MainActor
@Stateful
final class MediaViewModel: ViewModel {

    @CasePathable
    enum Action {
        case refresh

        var transition: Transition {
            .loop(.refreshing)
        }
    }

    enum State {
        case error
        case initial
        case refreshing
    }

    @Published
    private(set) var mediaItems: OrderedSet<MediaType> = []

    /// tvOS: each tile's resolved random backdrop image source(s), keyed by `MediaType.id`. The VM owns
    /// these (rather than each tile fetching its own) so the launch prefetch and the on-screen tiles
    /// use the SAME images — making the warmed cache an actual hit. The tvOS `MediaItem` reads from here.
    @Published
    private(set) var tileImageSources: [String: [ImageSource]] = [:]

    // Warms the resolved backdrops into Nuke's cache so tiles appear without an on-screen download.
    private let backdropPrefetcher = ImagePrefetcher()
    private var hasPrefetched = false
    private var isPreparingTiles = false

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        mediaItems.removeAll()
        mediaItems.elements = try await loadMediaItemList()
    }

    /// Builds the ordered list of media tiles (libraries + Favorites/Watchlist/Live TV). Extracted so
    /// both `_refresh` and the tvOS background prefetch can reuse it.
    private func loadMediaItemList() async throws -> [MediaType] {
        // The Watchlist tile is a tvOS-only addition (the KefinTweaks "Likes" list); iOS keeps its
        // original Media grid untouched.
        let includeWatchlist: Bool = {
            #if os(tvOS)
            true
            #else
            false
            #endif
        }()

        return try await getUserViews()
            .compactMap { userView in
                if userView.collectionType == .livetv {
                    return .liveTV(userView)
                }

                return .collectionFolder(userView)
            }
            // Prepended in reverse of display order: Favorites ends up first, then Watchlist.
            .prepending(.watchlist, if: includeWatchlist)
            .prepending(.favorites, if: Defaults[.Customization.Library.showFavorites])
    }

    private func getUserViews() async throws -> [BaseItemDto] {

        let client = try authenticatedClient
        let parameters = try Paths.GetUserViewsParameters(userID: authenticatedUser.id)
        let userViewsPath = Paths.getUserViews(parameters: parameters)
        async let userViews = client.send(userViewsPath)

        async let excludedLibraryIDs = getExcludedLibraries()

        // folders has `type = UserView`, but we manually
        // force it to `folders` for better view handling
        return try await (userViews.value.items ?? [])
            .coalesced(property: \.collectionType, with: .folders)
            .intersecting(CollectionType.supportedCases, using: \.collectionType)
            .subtracting(excludedLibraryIDs, using: \.id)
            .map { item in

                if item.type == .userView, item.collectionType == .folders {
                    return item.mutating(\.type, with: .folder)
                }

                return item
            }
    }

    private func getExcludedLibraries() async throws -> [String] {
        let currentUserPath = Paths.getCurrentUser
        let response = try await send(currentUserPath)

        return response.value.configuration?.myMediaExcludes ?? []
    }

    func randomItemImageSources(for mediaType: MediaType) async throws -> [ImageSource] {

        // live tv doesn't have random
        if case MediaType.liveTV = mediaType {
            return []
        }

        // downloads doesn't have random
        if mediaType == .downloads {
            return []
        }

        var parentID: String?

        if case let MediaType.collectionFolder(item) = mediaType {
            parentID = item.id
        }

        var filters: [ItemTrait]?

        if mediaType == .favorites {
            filters = [.isFavorite]
        } else if mediaType == .watchlist {
            filters = [.likes]
        }

        var parameters = Paths.GetItemsParameters()
        // tvOS keeps only items that actually have a backdrop, so request a larger pool to choose from.
        #if os(tvOS)
        parameters.limit = 8
        #else
        parameters.limit = 3
        #endif
        parameters.isRecursive = true
        parameters.parentID = parentID
        parameters.includeItemTypes = BaseItemKind.supportedCases
        parameters.filters = filters
        parameters.sortBy = [ItemSortBy.random]

        let request = Paths.getItems(parameters: parameters)
        let response = try await send(request)
        let items = response.value.items ?? []

        #if os(tvOS)
        // tvOS Media tiles show a clean BACKDROP (no baked-in titles), high-res for the large tiles.
        // Keep only items that actually have a backdrop; fall back to landscape sources if none do.
        let backdrops = items.compactMap { item -> ImageSource? in
            guard item.backdropImageTags?.isNotEmpty == true else { return nil }
            return item.imageSource(.backdrop, maxWidth: 800)
        }
        if backdrops.isNotEmpty {
            return backdrops
        }
        return items.flatMap { $0.landscapeImageSources(maxWidth: 800) }
        #else
        return items.flatMap { $0.landscapeImageSources(maxWidth: 200) }
        #endif
    }

    #if os(tvOS)

    /// One-shot background warm at launch (called from `HomeView`, mirroring requests/search/livetv):
    /// loads the tile list, resolves each tile's random backdrop, and prefetches them into the cache —
    /// so the FIRST visit to the Media tab shows the artwork instantly instead of fetching + blurring in.
    func prefetchIfNeeded() async {
        guard !hasPrefetched else { return }
        hasPrefetched = true
        await prepareTileImages(reloadList: true)
    }

    /// Resolves each tile's random backdrop image source and warms the cache. `reloadList` rebuilds the
    /// tile list first (needed before it exists). Called: once at launch, on first appear if still
    /// empty, and on every Media-tab EXIT to pre-roll fresh backdrops while off-screen.
    func prepareTileImages(reloadList: Bool) async {
        guard !isPreparingTiles else { return }
        isPreparingTiles = true
        defer { isPreparingTiles = false }

        if reloadList || mediaItems.isEmpty {
            if let media = try? await loadMediaItemList() {
                mediaItems.elements = media
            }
        }

        var resolved: [String: [ImageSource]] = [:]
        for type in mediaItems {
            guard let id = type.id else { continue }
            resolved[id] = await resolveImageSources(for: type)
        }
        tileImageSources = resolved

        // Warm the freshly-resolved backdrops so the tiles don't download on-screen.
        let urls = resolved.values.flatMap(\.self).compactMap(\.url)
        backdropPrefetcher.startPrefetching(with: urls)
    }

    /// The backdrop source(s) for a single tile: a clean random backdrop for libraries/Favorites/
    /// Watchlist; the Live TV view's own backdrop (or primary) for Live TV.
    private func resolveImageSources(for mediaType: MediaType) async -> [ImageSource] {
        if case let MediaType.liveTV(item) = mediaType {
            if item.backdropImageTags?.isNotEmpty == true {
                return [item.imageSource(.backdrop, maxWidth: 800)]
            }
            return [item.imageSource(.primary, maxWidth: 800)]
        }
        return await (try? randomItemImageSources(for: mediaType)) ?? []
    }

    #endif
}
