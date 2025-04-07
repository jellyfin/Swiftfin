//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

enum DeepLinkType: String, CaseIterable {
    /// Common trailer platforms
    case youtube
    case vimeo

    /// Apple platforms
    case appleTV
    case itunes

    /// Streaming services
    case netflix
    case disneyPlus
    case amazonPrime
    case hboMax
    case hulu
    case peacock
    case paramountPlus

    /// Other video platforms
    case dailymotion
    case twitch
    case imdb
    case tmdb

    /// Unknown URL
    case unknown

    // MARK: Display Title

    var displayTitle: String {
        switch self {
        case .youtube:
            return "YouTube"
        case .vimeo:
            return "Vimeo"
        case .appleTV:
            return "Apple TV"
        case .itunes:
            return "iTunes"
        case .netflix:
            return "Netflix"
        case .disneyPlus:
            return "Disney+"
        case .amazonPrime:
            return "Amazon Prime Video"
        case .hboMax:
            return "HBO Max"
        case .hulu:
            return "Hulu"
        case .peacock:
            return "Peacock"
        case .paramountPlus:
            return "Paramount+"
        case .dailymotion:
            return "Dailymotion"
        case .twitch:
            return "Twitch"
        case .imdb:
            return "IMDb"
        case .tmdb:
            return "TMDb"
        case .unknown:
            return L10n.unknown
        }
    }

    // MARK: URL Prefix

    var prefix: String {
        switch self {
        case .youtube:
            return "youtube://"
        case .vimeo:
            return "vimeo://"
        case .appleTV:
            return "com.apple.tv://"
        case .itunes:
            return "itms-apps://"
        case .netflix:
            return "netflix://"
        case .disneyPlus:
            return "disneyplus://"
        case .amazonPrime:
            return "primevideo://"
        case .hboMax:
            return "hbomax://"
        case .hulu:
            return "hulu://"
        case .peacock:
            return "peacocktv://"
        case .paramountPlus:
            return "paramountplus://"
        case .dailymotion:
            return "dailymotion://"
        case .twitch:
            return "twitch://"
        case .imdb:
            return "imdb://"
        case .tmdb:
            return "tmdb://"
        case .unknown:
            return ""
        }
    }

    // MARK: - Get DeepLink from a Prefix String

    static func fromPrefix(_ prefix: String) -> DeepLinkType {
        DeepLinkType.allCases.first { $0.prefix == prefix } ?? .unknown
    }

    // MARK: - Get DeepLink from a URL String

    static func fromURL(_ urlString: String) -> DeepLinkType {
        for type in DeepLinkType.allCases where type != .unknown {
            if urlString.hasPrefix(type.prefix) {
                return type
            }
        }

        guard let url = URL(string: urlString) else {
            return .unknown
        }

        let hostString = url.host ?? ""

        if hostString.contains("youtube") || hostString.contains("youtu.be") {
            return .youtube
        } else if hostString.contains("vimeo") {
            return .vimeo
        } else if hostString.contains("netflix") {
            return .netflix
        } else if hostString.contains("disneyplus") {
            return .disneyPlus
        } else if hostString.contains("amazon") && url.path.contains("/video") {
            return .amazonPrime
        } else if hostString.contains("hbomax") || hostString.contains("max.com") {
            return .hboMax
        } else if hostString.contains("hulu") {
            return .hulu
        } else if hostString.contains("peacocktv") {
            return .peacock
        } else if hostString.contains("paramountplus") {
            return .paramountPlus
        } else if hostString.contains("dailymotion") {
            return .dailymotion
        } else if hostString.contains("twitch") {
            return .twitch
        } else if hostString.contains("imdb") {
            return .imdb
        } else if hostString.contains("themoviedb") {
            return .tmdb
        }

        return .unknown
    }
}
