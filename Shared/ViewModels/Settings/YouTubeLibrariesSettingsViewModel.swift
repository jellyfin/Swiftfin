//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

@MainActor
final class YouTubeLibrariesSettingsViewModel: ViewModel {

    enum State: Hashable {
        case initial
        case loading
        case content
        case error(ErrorMessage)
    }

    @Published
    private(set) var libraries: [TubeArchivistLibrary] = []

    @Published
    var state: State = .initial

    func load() async {
        state = .loading

        do {
            libraries = try await TubeArchivistLibraryDetector.fetchLibraries(for: userSession)
            state = .content
        } catch {
            state = .error(.init(error.localizedDescription))
        }
    }
}
