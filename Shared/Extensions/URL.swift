//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

extension URL {

    init?(string: String?) {
        guard let string = string else { return nil }
        self.init(string: string)
    }
}

extension URL {

    static var documents: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var downloads: URL {
        documents.appendingPathComponent("Downloads")
    }

    static var tmp: URL {
        URL(string: NSTemporaryDirectory())!
    }

    static let swiftfinGithub: URL = URL(string: "https://github.com/jellyfin/Swiftfin")!

    static let swiftfinGithubIssues: URL = URL(string: "https://github.com/jellyfin/Swiftfin/issues")!

    static let jellyfinDocsDevices: URL = URL(string: "https://jellyfin.org/docs/general/server/devices")!

    static let jellyfinDocsTasks: URL = URL(string: "https://jellyfin.org/docs/general/server/tasks")!

    static let jellyfinDocsUsers: URL = URL(string: "https://jellyfin.org/docs/general/server/users")!

    static let jellyfinDocsManagingUsers: URL = URL(string: "https://jellyfin.org/docs/general/server/users/adding-managing-users")!

    func isDirectoryAndReachable() throws -> Bool {
        guard try resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true else {
            return false
        }
        return try checkResourceIsReachable()
    }

    func directoryTotalAllocatedSize(includingSubfolders: Bool = false) throws -> Int? {
        guard try isDirectoryAndReachable() else { return nil }

        if includingSubfolders {
            guard let urls = FileManager.default.enumerator(at: self, includingPropertiesForKeys: nil)?.allObjects as? [URL]
            else { return nil }
            return try urls.lazy.reduce(0) {
                try ($1.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize ?? 0) + $0
            }
        }

        return try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil).lazy.reduce(0) {
            try (
                $1.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
                    .totalFileAllocatedSize ?? 0
            ) + $0
        }
    }

    // doesn't have `?` but doesn't matter
    var pathAndQuery: String? {
        path + (query ?? "")
    }

    var sizeOnDisk: Int {
        do {
            guard let size = try directoryTotalAllocatedSize(includingSubfolders: true) else { return -1 }
            return size
        } catch {
            return -1
        }
    }

    var components: URLComponents? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)
    }
}
