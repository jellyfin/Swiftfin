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
            if source.requiresPathValidation, !source.requiredPathComponent.contains(where: { url.path.contains($0) }) {
                continue
            }

            guard let deepLink = source.buildDeepLink(from: url) else {
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

    struct Source: Hashable, Identifiable {

        let id: String

        let displayTitle: String
        let deepLinkScheme: String
        let hostPatterns: [String]
        let requiresPathValidation: Bool
        let requiredPathComponent: [String]
        let parseRegex: String?

        fileprivate init(
            displayTitle: String,
            deepLinkScheme: String,
            hostPatterns: [String],
            requiresPathValidation: Bool = false,
            requiredPathComponent: [String] = [],
            parseRegex: String? = nil
        ) {
            self.id = displayTitle
            self.displayTitle = displayTitle
            self.deepLinkScheme = deepLinkScheme
            self.hostPatterns = hostPatterns
            self.requiresPathValidation = requiresPathValidation
            self.requiredPathComponent = requiredPathComponent
            self.parseRegex = parseRegex
        }

        func buildDeepLink(from url: URL) -> URL? {
            if let parseRegex = parseRegex {
                do {
                    let regex = try NSRegularExpression(pattern: parseRegex, options: [])
                    let urlString = url.absoluteString
                    let range = NSRange(location: 0, length: urlString.utf16.count)

                    if let match = regex.firstMatch(in: urlString, options: [], range: range),
                       match.numberOfRanges > 1
                    {
                        let matchRange = match.range(at: 1)
                        if let swiftRange = Range(matchRange, in: urlString) {
                            let extractedID = String(urlString[swiftRange])
                            return URL(string: "\(deepLinkScheme)\(extractedID)")
                        }
                    }
                } catch {
                    return nil
                }

                return nil
            }

            return URL(string: "\(deepLinkScheme)\(url.absoluteString)")
        }
    }
}

extension ExternalTrailerURL.Source {

    static let appleTV = Self(
        displayTitle: "Apple TV",
        deepLinkScheme: "com.apple.tv://",
        hostPatterns: ["tv.apple.com"],
        requiresPathValidation: true,
        requiredPathComponent: ["/clip/", "show/", "/movie/"]
    )

    static let vimeo = Self(
        displayTitle: "Vimeo",
        deepLinkScheme: "vimeo://video/",
        hostPatterns: ["vimeo.com"],
        parseRegex: #"vimeo\.com/(?:video/)?(\d+)"#
    )

    static let youtube = Self(
        displayTitle: "YouTube",
        deepLinkScheme: "youtube://",
        hostPatterns: ["youtube.com", "youtu.be", "m.youtube.com"]
    )

    static var allCases: [Self] = [
        .appleTV,
        .vimeo,
        .youtube,
    ]
}
