//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

enum PreviewImageScrubbingOption: CaseIterable, Displayable, Hashable, Storable {

    case trickplay(fallbackToChapters: Bool = true)
    case chapters
    case disabled

    var displayTitle: String {
        switch self {
        case .trickplay: "Trickplay"
        case .disabled: L10n.disabled
        case .chapters: "Chapters"
        }
    }

    // TODO: enhance full screen determination
    //       - allow checking against image size?
    var supportsFullscreen: Bool {
        switch self {
        case .trickplay: true
        case .disabled, .chapters: false
        }
    }

    static var allCases: [PreviewImageScrubbingOption] {
        [.trickplay(), .chapters, .disabled]
    }
}
