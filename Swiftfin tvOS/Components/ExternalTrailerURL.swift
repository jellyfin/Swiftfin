//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
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
            if let requiredPathComponents = source.requiredPathComponents {
                if !requiredPathComponents.contains(where: { url.path.contains($0) }) {
                    continue
                }
            }

            guard let deepLink = source.buildDeepLink(url) else {
                continue
            }

            self.source = source
            self.deepLink = deepLink
            return
        }

        return nil
    }
}

extension ExternalTrailerURL {

    struct Source {

        let displayTitle: String
        let hostPatterns: [String]
        let requiredPathComponents: [String]?
        let buildDeepLink: (URL) -> URL?

        fileprivate init(
            displayTitle: String,
            hostPatterns: [String],
            requiredPathComponents: [String]? = nil,
            buildDeepLink: @escaping (URL) -> URL?
        ) {
            self.displayTitle = displayTitle
            self.hostPatterns = hostPatterns
            self.requiredPathComponents = requiredPathComponents
            self.buildDeepLink = buildDeepLink
        }
    }
}

extension ExternalTrailerURL.Source {

    static let appleTV = Self(
        displayTitle: "Apple TV",
        hostPatterns: ["tv.apple.com"],
        requiredPathComponents: ["/clip/", "/show/", "/movie/"]
    ) { url in
        URL(string: "com.apple.tv://\(url.absoluteString)")
    }

    static let vimeo = Self(
        displayTitle: "Vimeo",
        hostPatterns: ["vimeo.com"]
    ) { url in
        let pattern = /vimeo\.com\/(?:video\/)?(\d+)/
        guard let match = url.absoluteString.firstMatch(of: pattern) else {
            return nil
        }
        let videoId = String(match.1)
        return URL(string: "vimeo://video/\(videoId)")
    }

    static let youtube = Self(
        displayTitle: "YouTube",
        hostPatterns: ["youtube.com", "youtu.be", "m.youtube.com"]
    ) { url in
        URL(string: "youtube://\(url.absoluteString)")
    }

    static var allCases: [Self] = [
        .appleTV,
        .vimeo,
        .youtube,
    ]
}
