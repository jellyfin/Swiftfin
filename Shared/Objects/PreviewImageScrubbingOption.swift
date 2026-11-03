//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum PreviewImageScrubbingOption: CaseIterable, Displayable, Hashable, Storable {

    case trickplay(fallbackToChapters: Bool = true)
    case chapters
    case disabled

    var displayTitle: String {
        switch self {
        case .trickplay:
            L10n.trickplays
        case .disabled:
            L10n.disabled
        case .chapters:
            L10n.chapters
        }
    }

    static var allCases: [PreviewImageScrubbingOption] {
        [.trickplay(), .chapters, .disabled]
    }
}
