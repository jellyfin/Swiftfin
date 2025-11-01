//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

struct ExternalTrailerURL {

    let source: Source
    let deepLink: URL

    var canBeOpened: Bool {
        UIApplication.shared.canOpenURL(deepLink)
    }

    init?(string: String) {
        guard let url = URL(string: string),
              let host = url.host?.lowercased()
        else {
            return nil
        }

        for source in Source.allCases where source.hostPatterns.contains(where: { host.contains($0) }) {
            if source.requiresPathValidation, !url.path.contains(source.requiredPathComponent) {
                continue
            }

            guard let deepLink = source.buildDeepLink(from: url) else {
                continue
            }

            self.source = source
            self.deepLink = url
            return
        }

        return nil
    }
}

extension ExternalTrailerURL {

    struct Source: Hashable, Identifiable {

        let id: String

        let displayTitle: String
        let deepLinkScheme: String
        let hostPatterns: [String]
        let requiresPathValidation: Bool
        let requiredPathComponent: String

        fileprivate init(
            displayTitle: String,
            deepLinkScheme: String,
            hostPatterns: [String],
            requiresPathValidation: Bool = false,
            requiredPathComponent: String = ""
        ) {
            self.id = displayTitle
            self.displayTitle = displayTitle
            self.deepLinkScheme = deepLinkScheme
            self.hostPatterns = hostPatterns
            self.requiresPathValidation = requiresPathValidation
            self.requiredPathComponent = requiredPathComponent
        }

        func buildDeepLink(from url: URL) -> URL? {
            URL(string: "\(deepLinkScheme)\(url.absoluteString)")
        }
    }
}

extension ExternalTrailerURL.Source {

    static let youtube = Self(
        displayTitle: "YouTube",
        deepLinkScheme: "youtube://",
        hostPatterns: ["youtube.com", "youtu.be", "m.youtube.com"]
    )

    static let vimeo = Self(
        displayTitle: "Vimeo",
        deepLinkScheme: "vimeo://",
        hostPatterns: ["vimeo.com"]
    )

    static let appleTV = Self(
        displayTitle: "Apple TV",
        deepLinkScheme: "com.apple.tv://",
        hostPatterns: ["apple.com"],
        requiresPathValidation: true,
        requiredPathComponent: "/tv-app/"
    )

    static let itunes = Self(
        displayTitle: "iTunes",
        deepLinkScheme: "itms-apps://",
        hostPatterns: ["apple.com"],
        requiresPathValidation: true,
        requiredPathComponent: "/itunes/"
    )

    static let netflix = Self(
        displayTitle: "Netflix",
        deepLinkScheme: "netflix://",
        hostPatterns: ["netflix.com"]
    )

    static let disneyPlus = Self(
        displayTitle: "Disney+",
        deepLinkScheme: "disneyplus://",
        hostPatterns: ["disneyplus.com"]
    )

    static let amazonPrime = Self(
        displayTitle: "Amazon Prime Video",
        deepLinkScheme: "primevideo://",
        hostPatterns: ["amazon.com", "primevideo.com"],
        requiresPathValidation: true,
        requiredPathComponent: "/video"
    )

    static let hbo = Self(
        displayTitle: "HBO",
        deepLinkScheme: "hbomax://",
        hostPatterns: ["hbomax.com", "max.com"]
    )

    static let hulu = Self(
        displayTitle: "Hulu",
        deepLinkScheme: "hulu://",
        hostPatterns: ["hulu.com"]
    )

    static let peacock = Self(
        displayTitle: "Peacock",
        deepLinkScheme: "peacocktv://",
        hostPatterns: ["peacocktv.com"]
    )

    static let paramountPlus = Self(
        displayTitle: "Paramount+",
        deepLinkScheme: "paramountplus://",
        hostPatterns: ["paramountplus.com"]
    )

    static let dailymotion = Self(
        displayTitle: "Dailymotion",
        deepLinkScheme: "dailymotion://",
        hostPatterns: ["dailymotion.com"]
    )

    static let twitch = Self(
        displayTitle: "Twitch",
        deepLinkScheme: "twitch://",
        hostPatterns: ["twitch.tv"]
    )

    static let imdb = Self(
        displayTitle: "IMDb",
        deepLinkScheme: "imdb://",
        hostPatterns: ["imdb.com"]
    )

    static let tmdb = Self(
        displayTitle: "TMDb",
        deepLinkScheme: "tmdb://",
        hostPatterns: ["themoviedb.org"]
    )

    static var allCases: [Self] = [
        .youtube,
        .vimeo,
        .appleTV,
        .itunes,
        .netflix,
        .disneyPlus,
        .amazonPrime,
        .hbo,
        .hulu,
        .peacock,
        .paramountPlus,
        .dailymotion,
        .twitch,
        .imdb,
        .tmdb,
    ]
}
