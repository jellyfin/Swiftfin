//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation

@MainActor
final class IntroSkipPrompt: ObservableObject {

    @Published
    private(set) var target: ChapterNavigator.Chapter?

    private var itemID: String?
    private var currentIntro: ChapterNavigator.Chapter?
    private var dismissedIntro: ChapterNavigator.Chapter?

    func update(itemID: String?, navigator: ChapterNavigator, seconds: Duration) {
        if itemID != self.itemID {
            self.itemID = itemID
            dismissedIntro = nil
        }

        currentIntro = navigator.introChapter(at: seconds)

        let newTarget: ChapterNavigator.Chapter? = if let currentIntro, currentIntro != dismissedIntro {
            navigator.introSkipTarget(at: seconds)
        } else {
            nil
        }

        if newTarget != target {
            target = newTarget
        }
    }

    func dismiss() {
        guard target != nil else { return }
        dismissedIntro = currentIntro
        target = nil
    }
}
