//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct ChapterNavigator: Equatable {

    struct Chapter: Equatable {

        let title: String?
        let start: Duration

        var isIntro: Bool {
            title.map(ChapterNavigator.isIntroTitle) ?? false
        }
    }

    // Players can report a position slightly before a chapter start after seeking to it
    static let seekTolerance: Duration = .seconds(1)

    private static let introTitles: Set<String> = [
        "intro",
        "introduction",
        "opening",
        "opening credits",
        "opening theme",
        "op",
    ]

    let chapters: [Chapter]

    init(chapters: [Chapter]) {
        self.chapters = chapters.sorted { $0.start < $1.start }
    }

    func currentChapter(at seconds: Duration) -> Chapter? {
        chapters.last { $0.start <= seconds + Self.seekTolerance }
    }

    func nextChapter(after seconds: Duration) -> Chapter? {
        chapters.first { $0.start > seconds + Self.seekTolerance }
    }

    func introChapter(at seconds: Duration) -> Chapter? {
        guard let chapter = currentChapter(at: seconds), chapter.isIntro else { return nil }
        return chapter
    }

    func isInIntro(at seconds: Duration) -> Bool {
        introChapter(at: seconds) != nil
    }

    func introSkipTarget(at seconds: Duration) -> Chapter? {
        guard isInIntro(at: seconds) else { return nil }
        return chapters.first { $0.start > seconds + Self.seekTolerance && !$0.isIntro }
    }

    static func isIntroTitle(_ title: String) -> Bool {
        let normalized = title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return introTitles.contains(normalized)
    }
}
