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
        let dataCache = try? DataCache(name: "org.jellyfin.swiftfin") { name in
            URL(string: name)?.pathAndQuery() ?? name
        }

        dataCache?.sizeLimit = 1024 * 1024 * 500 // 500 MB

        return dataCache
    }()

    /// The `DataCache` used for images that should have longer lifetimes, usable without a
    /// connection, and not affected by other caching size limits.
    ///
    /// Current 150 MB is more than necessary.
    static let branding: DataCache? = {
        guard let root = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let path = root.appendingPathComponent("Cache/org.jellyfin.swiftfin.branding", isDirectory: true)

        let dataCache = try? DataCache(path: path) { name in

            // this adds some latency, but fine since
            // this DataCache is special
            if name.range(of: "Splashscreen") != nil {

                // TODO: potential issue where url ends with `/`, if
                //       not found, retry with `/` appended
                let prefix = name.trimmingSuffix("/Branding/Splashscreen?")

                // can assume that we are only requesting a server with
                // the key same as the current url
                guard let prefixURL = URL(string: prefix) else { return name }
                guard let server = try? SwiftfinStore.dataStack.fetchOne(
                    From<ServerModel>()
                        .where(\.$currentURL == prefixURL)
                ) else { return name }

                return "\(server.id)-splashscreen"
            } else {
                return URL(string: name)?.pathAndQuery() ?? name
            }
        }

        return dataCache
    }()
}
