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

    static func fromPrefix(_ prefix: String) -> DeepLinkType {
        DeepLinkType.allCases.first { $0.prefix == prefix } ?? .unknown
    }

    /// Parse a URL string to identify the deep link type
    /// - Parameter urlString: The URL to parse
    /// - Returns: The identified DeepLinkType
    static func fromURL(_ urlString: String) -> DeepLinkType {
        /// Check if it's already a deep link format
        for type in DeepLinkType.allCases where type != .unknown {
            if urlString.hasPrefix(type.prefix) {
                return type
            }
        }

        /// Not a direct deep link, try to parse from web URL
        guard let url = URL(string: urlString) else {
            return .unknown
        }

        // Match based on host name
        if url.host?.contains("youtube") == true || url.host?.contains("youtu.be") == true {
            return .youtube
        } else if url.host?.contains("vimeo") == true {
            return .vimeo
        } else if url.host?.contains("netflix") == true {
            return .netflix
        } else if url.host?.contains("disneyplus") == true {
            return .disneyPlus
        } else if url.host?.contains("amazon") == true && url.path.contains("/video") {
            return .amazonPrime
        } else if url.host?.contains("hbomax") == true || url.host?.contains("max.com") == true {
            return .hboMax
        } else if url.host?.contains("hulu") == true {
            return .hulu
        } else if url.host?.contains("peacocktv") == true {
            return .peacock
        } else if url.host?.contains("paramountplus") == true {
            return .paramountPlus
        } else if url.host?.contains("dailymotion") == true {
            return .dailymotion
        } else if url.host?.contains("twitch") == true {
            return .twitch
        } else if url.host?.contains("imdb") == true {
            return .imdb
        } else if url.host?.contains("themoviedb") == true {
            return .tmdb
        }

        /// If we can't identify a specific platform, return unknown
        return .unknown
    }
}
