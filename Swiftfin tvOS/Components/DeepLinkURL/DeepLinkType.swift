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

    // MARK: - Display Title

    /// Localization is not required for Proper Nouns
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

    // MARK: - Host Patterns

    private var hostPatterns: [String] {
        switch self {
        case .youtube:
            return ["youtube", "youtu.be"]
        case .vimeo:
            return ["vimeo"]
        case .netflix:
            return ["netflix"]
        case .disneyPlus:
            return ["disneyplus"]
        case .amazonPrime:
            return ["amazon"]
        case .hboMax:
            return ["hbomax", "max.com"]
        case .hulu:
            return ["hulu"]
        case .peacock:
            return ["peacocktv"]
        case .paramountPlus:
            return ["paramountplus"]
        case .dailymotion:
            return ["dailymotion"]
        case .twitch:
            return ["twitch"]
        case .imdb:
            return ["imdb"]
        case .tmdb:
            return ["themoviedb"]
        default:
            return []
        }
    }

    // MARK: - Get DeepLink from a Prefix String

    static func fromPrefix(_ prefix: String) -> DeepLinkType {
        DeepLinkType.allCases.first { $0.prefix == prefix } ?? .unknown
    }

    // MARK: - Get DeepLink from a URL String

    static func fromURL(_ urlString: String) -> DeepLinkType {
        if let typeFromPrefix = _checkDeepLinkPrefix(urlString) {
            return typeFromPrefix
        }

        guard let url = URL(string: urlString) else {
            return .unknown
        }

        return _detectFromWebURL(url)
    }

    // MARK: - Check Deep Link Prefix

    private static func _checkDeepLinkPrefix(_ urlString: String) -> DeepLinkType? {
        for type in DeepLinkType.allCases where type != .unknown {
            if urlString.hasPrefix(type.prefix) {
                return type
            }
        }
        return nil
    }

    // MARK: - Detect from Web URL

    private static func _detectFromWebURL(_ url: URL) -> DeepLinkType {
        let hostString = url.host ?? ""

        for type in DeepLinkType.allCases where type != .unknown {
            if type.matchesHost(hostString, url: url) {
                return type
            }
        }

        return .unknown
    }

    // MARK: - Matches Host

    private func matchesHost(_ hostString: String, url: URL) -> Bool {
        for pattern in hostPatterns {
            if hostString.contains(pattern) {
                return validateSpecialCases(for: self, url: url)
            }
        }
        return false
    }

    // MARK: - Validate Special Cases

    private func validateSpecialCases(for type: DeepLinkType, url: URL) -> Bool {
        switch type {
        case .amazonPrime:
            return url.path.contains("/video")
        default:
            return true
        }
    }
}
