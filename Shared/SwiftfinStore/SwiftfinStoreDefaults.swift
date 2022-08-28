//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import UIKit

// TODO: Organize

extension UserDefaults {
    static let generalSuite = UserDefaults(suiteName: "swiftfinstore-general-defaults")!
    static let universalSuite = UserDefaults(suiteName: "swiftfinstore-universal-defaults")!
}

extension Defaults.Keys {
    // Universal settings
    static let defaultHTTPScheme = Key<HTTPScheme>("defaultHTTPScheme", default: .http, suite: .universalSuite)
    static let appAppearance = Key<AppAppearance>("appAppearance", default: .system, suite: .universalSuite)

    // General settings
    static let lastServerUserID = Defaults.Key<String?>("lastServerUserID", suite: .generalSuite)
    static let inNetworkBandwidth = Key<Int>("InNetworkBandwidth", default: 40_000_000, suite: .generalSuite)
    static let outOfNetworkBandwidth = Key<Int>("OutOfNetworkBandwidth", default: 40_000_000, suite: .generalSuite)

    enum Customization {
        static let showFlattenView = Key<Bool>("showFlattenView", default: true, suite: .generalSuite)
        static let itemViewType = Key<ItemViewType>("itemViewType", default: .compactLogo, suite: .generalSuite)

        static let showPosterLabels = Key<Bool>("showPosterLabels", default: true, suite: .generalSuite)
        static let nextUpPosterType = Key<PosterType>("nextUpPosterType", default: .portrait, suite: .generalSuite)
        static let recentlyAddedPosterType = Key<PosterType>("recentlyAddedPosterType", default: .portrait, suite: .generalSuite)
        static let latestInLibraryPosterType = Key<PosterType>("latestInLibraryPosterType", default: .portrait, suite: .generalSuite)
        static let recommendedPosterType = Key<PosterType>("recommendedPosterType", default: .portrait, suite: .generalSuite)
        static let searchPosterType = Key<PosterType>("searchPosterType", default: .portrait, suite: .generalSuite)
        static let libraryPosterType = Key<PosterType>("libraryPosterType", default: .portrait, suite: .generalSuite)

        enum Episodes {
            static let useSeriesLandscapeBackdrop = Key<Bool>("useSeriesBackdrop", default: true, suite: .generalSuite)
        }
    }

    // Video player / overlay settings
    static let overlayType = Key<OverlayType>("overlayType", default: .normal, suite: .generalSuite)
    static let jumpGesturesEnabled = Key<Bool>("gesturesEnabled", default: true, suite: .generalSuite)
    static let systemControlGesturesEnabled = Key<Bool>(
        "systemControlGesturesEnabled",
        default: true,
        suite: .generalSuite
    )
    static let playerGesturesLockGestureEnabled = Key<Bool>(
        "playerGesturesLockGestureEnabled",
        default: true,
        suite: .generalSuite
    )
    static let seekSlideGestureEnabled = Key<Bool>(
        "seekSlideGestureEnabled",
        default: true,
        suite: .generalSuite
    )
    static let videoPlayerJumpForward = Key<VideoPlayerJumpLength>(
        "videoPlayerJumpForward",
        default: .fifteen,
        suite: .generalSuite
    )
    static let videoPlayerJumpBackward = Key<VideoPlayerJumpLength>(
        "videoPlayerJumpBackward",
        default: .fifteen,
        suite: .generalSuite
    )
    static let autoplayEnabled = Key<Bool>("autoPlayNextItem", default: true, suite: .generalSuite)
    static let resumeOffset = Key<Bool>("resumeOffset", default: false, suite: .generalSuite)
    static let subtitleFontName = Key<String>(
        "subtitleFontName",
        default: UIFont.systemFont(ofSize: 14).fontName,
        suite: .generalSuite
    )
    static let subtitleSize = Key<SubtitleSize>("subtitleSize", default: .regular, suite: .generalSuite)

    // Should show video player items
    static let shouldShowPlayPreviousItem = Key<Bool>("shouldShowPreviousItem", default: true, suite: .generalSuite)
    static let shouldShowPlayNextItem = Key<Bool>("shouldShowNextItem", default: true, suite: .generalSuite)
    static let shouldShowAutoPlay = Key<Bool>("shouldShowAutoPlayNextItem", default: true, suite: .generalSuite)

    // Should show missing seasons and episodes
    static let shouldShowMissingSeasons = Key<Bool>("shouldShowMissingSeasons", default: true, suite: .generalSuite)
    static let shouldShowMissingEpisodes = Key<Bool>("shouldShowMissingEpisodes", default: true, suite: .generalSuite)

    // Should show video player items in overlay menu
    static let shouldShowJumpButtonsInOverlayMenu = Key<Bool>(
        "shouldShowJumpButtonsInMenu",
        default: true,
        suite: .generalSuite
    )

    static let shouldShowChaptersInfoInBottomOverlay = Key<Bool>(
        "shouldShowChaptersInfoInBottomOverlay",
        default: true,
        suite: .generalSuite
    )

    // Experimental settings
    enum Experimental {
        static let syncSubtitleStateWithAdjacent = Key<Bool>(
            "experimental.syncSubtitleState",
            default: false,
            suite: .generalSuite
        )
        static let forceDirectPlay = Key<Bool>("forceDirectPlay", default: false, suite: .generalSuite)
        static let nativePlayer = Key<Bool>("nativePlayer", default: false, suite: .generalSuite)
        static let liveTVAlphaEnabled = Key<Bool>("liveTVAlphaEnabled", default: false, suite: .generalSuite)
        static let liveTVForceDirectPlay = Key<Bool>("liveTVForceDirectPlay", default: false, suite: .generalSuite)
        static let liveTVNativePlayer = Key<Bool>("liveTVNativePlayer", default: false, suite: .generalSuite)
    }

    // tvos specific
    static let downActionShowsMenu = Key<Bool>("downActionShowsMenu", default: true, suite: .generalSuite)
    static let confirmClose = Key<Bool>("confirmClose", default: false, suite: .generalSuite)
}
