//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Foundation
import Nuke

// TODO: when `Storage` is implemented, could allow limits on sizes

// Note: For better support with multi-url servers, ignore the
//       host and only use path + query which has ids and tags

extension DataCache {
    enum Swiftfin {}
}

extension DataCache.Swiftfin {

    static let `default`: DataCache? = {

        let dataCache = try? DataCache(name: "org.jellyfin.swiftfin/Images") { name in

            guard var components = name.url?.components else { return nil }

            var maxWidthValue: String? = nil

            if let maxWidth = components.queryItems?.first(where: { $0.name == "maxWidth" }) {
                maxWidthValue = maxWidth.value
                components.queryItems = components.queryItems?.filter { $0.name != "maxWidth" }
            }

            guard let newURL = components.url, let urlSHA = newURL.absoluteString.sha1 else { return nil }

            if let maxWidthValue {
                return urlSHA + "-\(maxWidthValue)"
            } else {
                return urlSHA
            }
        }

        dataCache?.sizeLimit = 1024 * 1024 * 1000 // 500 MB

        return dataCache
    }()

    /// The `DataCache` used for server and user images that should be usable
    /// without a consistent connection.
    static let branding: DataCache? = {
        guard let root = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let path = root.appendingPathComponent("Cache/org.jellyfin.swiftfin.branding", isDirectory: true)

        let dataCache = try? DataCache(path: path) { name in

            guard let url = name.url else { return name }

            // Since multi-url servers is supported,
            // key splashscreens with the server ID.
            //
            // Additional latency from Core Data round
            // trip is acceptable.
            if url.path.contains("Splashscreen") {

                // Account for hosting at a path
                guard let prefixURL = url.absoluteString.trimmingSuffix("/Branding/Splashscreen?").url else { return nil }

                // We can assume that the request
                // is from the current server
                let urlFilter: Where<ServerModel> = Where(\.$currentURL == prefixURL)
                guard let server = try? SwiftfinStore.dataStack.fetchOne(
                    From<ServerModel>()
                        .where(urlFilter)
                ) else { return nil }

                return "\(server.id)-splashscreen".sha1
            } else {
                // TODO: size differences...
                return url.pathAndQuery()?.sha1
            }
        }

        return dataCache
    }()
}
