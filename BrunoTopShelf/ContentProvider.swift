//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

//
// ┌─────────────────────────────────────────────────────────────────────────────────────────┐
// │ TEMPLATE — NOT YET A BUILD TARGET.                                                         │
// │ This file is intentionally OUTSIDE every synchronized source group, so it is not compiled │
// │ until the owner creates the "BrunoTopShelf" TV Top Shelf extension target in Xcode and    │
// │ adds this file to it. See docs/TOP_SHELF_SETUP.md for the exact steps (target, App Group, │
// │ entitlements, signing). Until then nothing here affects the app build.                    │
// └─────────────────────────────────────────────────────────────────────────────────────────┘
//
// Provides the system Top Shelf (the wide banner above the app icon on the tvOS home screen):
// Continue Watching + Recently Added rows with poster art, each deep-linking back into Bruno.
// Auth comes from the shared App Group via BrunoTopShelfCredentials (add that file to this target
// too). Talks to Jellyfin over plain URLSession so the extension stays lightweight (no SDK/macros).

import Foundation
import TVServices

final class ContentProvider: TVTopShelfContentProvider {

    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        // No signed-in session shared yet → nil, so tvOS shows the static `BRUNO.` top-shelf image.
        guard let credentials = BrunoTopShelfCredentials.load() else {
            completionHandler(nil)
            return
        }

        Task {
            let sections = await Self.makeSections(credentials: credentials)
            guard !sections.isEmpty else {
                completionHandler(nil)
                return
            }
            completionHandler(TVTopShelfSectionedContent(sections: sections))
        }
    }

    // MARK: Sections

    private static func makeSections(
        credentials: BrunoTopShelfCredentials
    ) async -> [TVTopShelfItemCollection<TVTopShelfSectionedItem>] {

        async let resume = fetchResume(credentials: credentials)
        async let latest = fetchLatest(credentials: credentials)

        var sections: [TVTopShelfItemCollection<TVTopShelfSectionedItem>] = []

        let resumeItems = await resume.map { item($0, credentials: credentials) }
        if !resumeItems.isEmpty {
            let collection = TVTopShelfItemCollection(items: resumeItems)
            collection.title = "Continue Watching"
            sections.append(collection)
        }

        let latestItems = await latest.map { item($0, credentials: credentials) }
        if !latestItems.isEmpty {
            let collection = TVTopShelfItemCollection(items: latestItems)
            collection.title = "Recently Added"
            sections.append(collection)
        }

        return sections
    }

    private static func item(
        _ dto: JellyfinItem,
        credentials: BrunoTopShelfCredentials
    ) -> TVTopShelfSectionedItem {
        let shelfItem = TVTopShelfSectionedItem(identifier: dto.id)
        shelfItem.title = dto.name ?? ""
        shelfItem.imageShape = .poster

        if let imageURL = imageURL(for: dto, credentials: credentials) {
            shelfItem.setImageURL(imageURL, for: .screenScale1x)
            shelfItem.setImageURL(imageURL, for: .screenScale2x)
        }

        // Deep link back into Bruno using the app's existing `swiftfin://…/item/<id>` scheme,
        // which DeepLinkHandler already accepts (see docs/TOP_SHELF_SETUP.md §5).
        if let deepLink = credentials.itemDeepLink(itemID: dto.id) {
            let action = TVTopShelfAction(url: deepLink)
            shelfItem.displayAction = action
            shelfItem.playAction = action
        }

        return shelfItem
    }

    private static func imageURL(
        for dto: JellyfinItem,
        credentials: BrunoTopShelfCredentials
    ) -> URL? {
        var components = URLComponents(
            url: credentials.serverURL.appendingPathComponent("Items/\(dto.id)/Images/Primary"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "maxWidth", value: "500"),
            URLQueryItem(name: "quality", value: "90"),
            // tvOS fetches this URL itself (no auth header possible), so authenticate via query
            // for servers that require auth on image endpoints.
            URLQueryItem(name: "api_key", value: credentials.accessToken),
        ]
        return components?.url
    }

    // MARK: Jellyfin REST (no SDK)

    private static func fetchResume(credentials: BrunoTopShelfCredentials) async -> [JellyfinItem] {
        var components = URLComponents(
            url: credentials.serverURL.appendingPathComponent("Users/\(credentials.userID)/Items/Resume"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "Limit", value: "12"),
            URLQueryItem(name: "MediaTypes", value: "Video"),
        ]
        let envelope: ItemsEnvelope? = await get(components?.url, token: credentials.accessToken)
        return envelope?.items ?? []
    }

    private static func fetchLatest(credentials: BrunoTopShelfCredentials) async -> [JellyfinItem] {
        var components = URLComponents(
            url: credentials.serverURL.appendingPathComponent("Users/\(credentials.userID)/Items/Latest"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "Limit", value: "12"),
            URLQueryItem(name: "IncludeItemTypes", value: "Movie,Series"),
        ]
        // /Items/Latest returns a bare array, not an envelope.
        let items: [JellyfinItem]? = await get(components?.url, token: credentials.accessToken)
        return items ?? []
    }

    private static func get<T: Decodable>(_ url: URL?, token: String) async -> T? {
        guard let url else { return nil }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "X-Emby-Token")
        request.timeoutInterval = 8
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }
}

// MARK: - Minimal Jellyfin models

struct ItemsEnvelope: Decodable {
    let items: [JellyfinItem]

    enum CodingKeys: String, CodingKey {
        case items = "Items"
    }
}

struct JellyfinItem: Decodable {
    let id: String
    let name: String?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
    }
}
