//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

enum DeepLinkURLSource: String, CaseIterable {
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
    case hbo
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

    // MARK: - Display Title

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
        case .hbo:
            return "HBO"
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

    // MARK: - URL Prefix

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
        case .hbo:
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

    // MARK: - Host Patterns

    var hostPatterns: [String] {
        switch self {
        case .youtube:
            return ["youtube.com", "youtu.be", "m.youtube.com", "youtu.be"]
        case .vimeo:
            return ["vimeo.com"]
        case .netflix:
            return ["netflix.com"]
        case .disneyPlus:
            return ["disneyplus.com"]
        case .amazonPrime:
            return ["amazon.com", "primevideo.com"]
        case .hbo:
            return ["hbomax.com", "max.com"]
        case .hulu:
            return ["hulu.com"]
        case .peacock:
            return ["peacocktv.com"]
        case .paramountPlus:
            return ["paramountplus.com"]
        case .dailymotion:
            return ["dailymotion.com"]
        case .twitch:
            return ["twitch.tv"]
        case .imdb:
            return ["imdb.com"]
        case .tmdb:
            return ["themoviedb.org"]
        default:
            return []
        }
    }

    // MARK: - Internal Pre-Computed Host Pattern Map

    private static let hostPatternMap: [String: DeepLinkURLSource] = {
        var map: [String: DeepLinkURLSource] = [:]
        for source in DeepLinkURLSource.allCases where source != .unknown {
            for pattern in source.hostPatterns {
                map[pattern] = source
            }
        }
        return map
    }()

    // MARK: - Validation

    func validate(url: URL) -> Bool {
        switch self {
        case .amazonPrime:
            return url.path.contains("/video")
        default:
            return true
        }
    }

    // MARK: - Get DeepLinkURLSource from Prefix

    static func fromPrefix(_ prefix: String) -> DeepLinkURLSource {
        allCases.first { $0.prefix == prefix } ?? .unknown
    }

    // MARK: - Get DeepLinkURLSource from URL

    static func fromURL(_ urlString: String) -> DeepLinkURLSource {
        /// Check for prefix matches first (most specific and often quicker)
        if let match = allCases.first(where: { urlString.hasPrefix($0.prefix) }) {
            return match
        }

        guard let url = URL(string: urlString),
              let host = url.host?.lowercased()
        else {
            return .unknown
        }

        /// Check for host pattern matches using the pre-computed map
        for (pattern, source) in hostPatternMap {
            if host.contains(pattern) {
                return source.validate(url: url) ? source : .unknown
            }
        }

        /// Fallback for Apple TV and iTunes which don't use host patterns
        if url.scheme == "https" || url.scheme == "http" {
            if host.contains("apple.com") && url.path.contains("/tv-app/") {
                return .appleTV
            }
            if host.contains("apple.com") && (url.path.contains("/itunes/") || url.path.contains("/app/")) {
                return .itunes
            }
        }

        /// Fallback to unknown
        return .unknown
    }
}
