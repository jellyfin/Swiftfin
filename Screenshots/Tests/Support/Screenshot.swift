//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import XCTest

enum Screenshot: String, CaseIterable {

    case home = "Home"
    case media = "Media"
    case library = "Library"
    case movie = "Movie"
    case series = "Series"
    case episode = "Episode"
    case playback = "Playback"
    case userSelection = "UserSelection"

    var headline: String {
        let headline = switch self {
        case .home:
            L10n.screenshotHeadlineHome
        case .media:
            L10n.screenshotHeadlineMedia
        case .library:
            L10n.screenshotHeadlineLibrary
        case .movie:
            L10n.screenshotHeadlineMovie
        case .series:
            L10n.screenshotHeadlineSeries
        case .episode:
            L10n.screenshotHeadlineEpisode
        case .playback:
            L10n.screenshotHeadlinePlayback
        case .userSelection:
            L10n.screenshotHeadlineUserSelection
        }

        return headline.localizedCapitalized
    }

    var subtitle: String {
        switch self {
        case .home:
            L10n.screenshotSubtitleHome
        case .media:
            L10n.screenshotSubtitleMedia
        case .library:
            L10n.screenshotSubtitleLibrary
        case .movie:
            L10n.screenshotSubtitleMovie
        case .series:
            L10n.screenshotSubtitleSeries
        case .episode:
            L10n.screenshotSubtitleEpisode
        case .playback:
            L10n.screenshotSubtitlePlayback(UIDevice.platform)
        case .userSelection:
            L10n.screenshotSubtitleUserSelection
        }
    }

    @MainActor
    func saveCaption() {
        let directory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("../../../build/Screenshots/Capture/\(UIDevice.platform)/\(Snapshot.deviceLanguage)")
            .standardized

        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? JSONEncoder()
            .encode(["headline": headline, "subtitle": subtitle])
            .write(to: directory.appendingPathComponent("\(rawValue).json"))
    }
}
