//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

struct ExternalTrailerSource {
    let type: SourceType
    let url: URL?

    var isValid: Bool {
        guard let url else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    init(_ urlString: String) {
        guard let url = URL(string: urlString),
              let host = url.host?.lowercased()
        else {
            self.type = .unknown
            self.url = nil
            return
        }

        for source in SourceType.allCases where source != .unknown {
            if source.hostPatterns.contains(where: { host.contains($0) }) {
                if source.requiresPathValidation && !url.path.contains(source.requiredPathComponent) {
                    continue
                }
                self.type = source
                self.url = source.buildDeepLink(from: url)
                return
            }
        }

        self.type = .unknown
        self.url = nil
    }
}

extension ExternalTrailerSource {

    enum SourceType: CaseIterable {
        case youtube
        case vimeo
        case appleTV
        case itunes
        case netflix
        case disneyPlus
        case amazonPrime
        case hbo
        case hulu
        case peacock
        case paramountPlus
        case dailymotion
        case twitch
        case imdb
        case tmdb
        case unknown

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

        var deepLinkScheme: String {
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

        var hostPatterns: [String] {
            switch self {
            case .youtube:
                return ["youtube.com", "youtu.be", "m.youtube.com"]
            case .vimeo:
                return ["vimeo.com"]
            case .appleTV:
                return ["apple.com"]
            case .itunes:
                return ["apple.com"]
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
            case .unknown:
                return []
            }
        }

        var requiresPathValidation: Bool {
            switch self {
            case .amazonPrime, .appleTV, .itunes:
                return true
            default:
                return false
            }
        }

        var requiredPathComponent: String {
            switch self {
            case .amazonPrime: return "/video"
            case .appleTV: return "/tv-app/"
            case .itunes: return "/itunes/"
            default: return ""
            }
        }

        func buildDeepLink(from url: URL) -> URL? {
            URL(string: "\(deepLinkScheme)\(url.absoluteString)")
        }
    }
}
