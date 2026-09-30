//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

extension MediaPlayerManager {

    var chapterNavigator: ChapterNavigator {
        ChapterNavigator(chapters: item.chapters ?? [])
    }

    func seek(to chapter: ChapterNavigator.Chapter) {
        seconds = chapter.start
        proxy?.setSeconds(chapter.start)
        setPlaybackRequestStatus(status: .playing)
    }
}
