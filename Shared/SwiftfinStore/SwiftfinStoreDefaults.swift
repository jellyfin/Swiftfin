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

extension SwiftfinStore {
    enum Defaults {
        static let generalSuite: UserDefaults = .init(suiteName: "swiftfinstore-general-defaults")!

        static let universalSuite: UserDefaults = .init(suiteName: "swiftfinstore-universal-defaults")!
    }
}

extension Defaults.Keys {
    // Universal settings
    static let defaultHTTPScheme = Key<HTTPScheme>("defaultHTTPScheme", default: .http, suite: SwiftfinStore.Defaults.universalSuite)
    static let appAppearance = Key<AppAppearance>("appAppearance", default: .system, suite: SwiftfinStore.Defaults.universalSuite)

    // General settings
    static let lastServerUserID = Defaults.Key<String?>("lastServerUserID", suite: SwiftfinStore.Defaults.generalSuite)
    static let inNetworkBandwidth = Key<Int>("InNetworkBandwidth", default: 40_000_000, suite: SwiftfinStore.Defaults.generalSuite)
    static let outOfNetworkBandwidth = Key<Int>("OutOfNetworkBandwidth", default: 40_000_000, suite: SwiftfinStore.Defaults.generalSuite)
    static let isAutoSelectSubtitles = Key<Bool>("isAutoSelectSubtitles", default: false, suite: SwiftfinStore.Defaults.generalSuite)
    static let autoSelectSubtitlesLangCode = Key<String>(
        "AutoSelectSubtitlesLangCode",
        default: "Auto",
        suite: SwiftfinStore.Defaults.generalSuite
    )
    static let autoSelectAudioLangCode = Key<String>("AutoSelectAudioLangCode", default: "Auto", suite: SwiftfinStore.Defaults.generalSuite)

    // Customize settings
    static let showPosterLabels = Key<Bool>("showPosterLabels", default: true, suite: SwiftfinStore.Defaults.generalSuite)
    static let showCastAndCrew = Key<Bool>("showCastAndCrew", default: true, suite: SwiftfinStore.Defaults.generalSuite)
    static let showFlattenView = Key<Bool>("showFlattenView", default: true, suite: SwiftfinStore.Defaults.generalSuite)

    // Video player / overlay settings
    static let overlayType = Key<OverlayType>("overlayType", default: .normal, suite: SwiftfinStore.Defaults.generalSuite)
    static let jumpGesturesEnabled = Key<Bool>("gesturesEnabled", default: true, suite: SwiftfinStore.Defaults.generalSuite)
    static let systemControlGesturesEnabled = Key<Bool>(
        "systemControlGesturesEnabled",
        default: true,
        suite: SwiftfinStore.Defaults.generalSuite
    )
    static let playerGesturesLockGestureEnabled = Key<Bool>(
        "playerGesturesLockGestureEnabled",
        default: true,
        suite: SwiftfinStore.Defaults.generalSuite
    )
    static let seekSlideGestureEnabled = Key<Bool>(
        "seekSlideGestureEnabled",
        default: true,
        suite: SwiftfinStore.Defaults.generalSuite
    )
    static let videoPlayerJumpForward = Key<VideoPlayerJumpLength>(
        "videoPlayerJumpForward",
        default: .fifteen,
        suite: SwiftfinStore.Defaults.generalSuite
    )
    static let videoPlayerJumpBackward = Key<VideoPlayerJumpLength>(
        "videoPlayerJumpBackward",
        default: .fifteen,
        suite: SwiftfinStore.Defaults.generalSuite
    )
    static let autoplayEnabled = Key<Bool>("autoPlayNextItem", default: true, suite: SwiftfinStore.Defaults.generalSuite)
    static let resumeOffset = Key<Bool>("resumeOffset", default: false, suite: SwiftfinStore.Defaults.generalSuite)
    static let subtitleFontName = Key<String>(
        "subtitleFontName",
        default: UIFont.systemFont(ofSize: 14).fontName,
        suite: SwiftfinStore.Defaults.generalSuite
    )
    static let subtitleSize = Key<SubtitleSize>("subtitleSize", default: .regular, suite: SwiftfinStore.Defaults.generalSuite)

    // Should show video player items
    static let shouldShowPlayPreviousItem = Key<Bool>("shouldShowPreviousItem", default: true, suite: SwiftfinStore.Defaults.generalSuite)
    static let shouldShowPlayNextItem = Key<Bool>("shouldShowNextItem", default: true, suite: SwiftfinStore.Defaults.generalSuite)
    static let shouldShowAutoPlay = Key<Bool>("shouldShowAutoPlayNextItem", default: true, suite: SwiftfinStore.Defaults.generalSuite)

    // Should show missing seasons and episodes
    static let shouldShowMissingSeasons = Key<Bool>("shouldShowMissingSeasons", default: true, suite: SwiftfinStore.Defaults.generalSuite)
    static let shouldShowMissingEpisodes = Key<Bool>("shouldShowMissingEpisodes", default: true, suite: SwiftfinStore.Defaults.generalSuite)

    // Should show video player items in overlay menu
    static let shouldShowJumpButtonsInOverlayMenu = Key<Bool>(
        "shouldShowJumpButtonsInMenu",
        default: true,
        suite: SwiftfinStore.Defaults.generalSuite
    )

    static let shouldShowChaptersInfoInBottomOverlay = Key<Bool>(
        "shouldShowChaptersInfoInBottomOverlay",
        default: true,
        suite: SwiftfinStore.Defaults.generalSuite
    )

    // Experimental settings
    enum Experimental {
        static let syncSubtitleStateWithAdjacent = Key<Bool>(
            "experimental.syncSubtitleState",
            default: false,
            suite: SwiftfinStore.Defaults.generalSuite
        )
        static let forceDirectPlay = Key<Bool>("forceDirectPlay", default: false, suite: SwiftfinStore.Defaults.generalSuite)
        static let nativePlayer = Key<Bool>("nativePlayer", default: false, suite: SwiftfinStore.Defaults.generalSuite)
        static let liveTVAlphaEnabled = Key<Bool>("liveTVAlphaEnabled", default: false, suite: SwiftfinStore.Defaults.generalSuite)
        static let liveTVForceDirectPlay = Key<Bool>("liveTVForceDirectPlay", default: false, suite: SwiftfinStore.Defaults.generalSuite)
        static let liveTVNativePlayer = Key<Bool>("liveTVNativePlayer", default: false, suite: SwiftfinStore.Defaults.generalSuite)
    }

    // tvos specific
    static let downActionShowsMenu = Key<Bool>("downActionShowsMenu", default: true, suite: SwiftfinStore.Defaults.generalSuite)
    static let confirmClose = Key<Bool>("confirmClose", default: false, suite: SwiftfinStore.Defaults.generalSuite)
    static let tvOSCinematicViews = Key<Bool>("tvOSCinematicViews", default: false, suite: SwiftfinStore.Defaults.generalSuite)
}
