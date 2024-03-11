//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import SwiftUI
import UIKit

// TODO: Organize

extension UserDefaults {
    static let generalSuite = UserDefaults(suiteName: "swiftfinstore-general-defaults")!
    static let universalSuite = UserDefaults(suiteName: "swiftfinstore-universal-defaults")!
}

extension Defaults.Keys {

    // Universal settings
    static let accentColor: Key<Color> = .init("accentColor", default: .jellyfinPurple, suite: .universalSuite)
    static let appAppearance = Key<AppAppearance>("appAppearance", default: .system, suite: .universalSuite)
    static let hapticFeedback: Key<Bool> = .init("hapticFeedback", default: true, suite: .universalSuite)
    static let lastServerUserID = Defaults.Key<String?>("lastServerUserID", suite: .universalSuite)

    // TODO: Replace with a cache
    static let libraryFilterStore = Key<[String: ItemFilterCollection]>("libraryFilterStore", default: [:], suite: .generalSuite)

    enum Customization {

        static let itemViewType = Key<ItemViewType>("itemViewType", default: .compactLogo, suite: .generalSuite)

        static let showPosterLabels = Key<Bool>("showPosterLabels", default: true, suite: .generalSuite)
        static let nextUpPosterType = Key<PosterType>("nextUpPosterType", default: .portrait, suite: .generalSuite)
        static let recentlyAddedPosterType = Key<PosterType>("recentlyAddedPosterType", default: .portrait, suite: .generalSuite)
        static let latestInLibraryPosterType = Key<PosterType>("latestInLibraryPosterType", default: .portrait, suite: .generalSuite)
        static let shouldShowMissingSeasons = Key<Bool>("shouldShowMissingSeasons", default: true, suite: .generalSuite)
        static let shouldShowMissingEpisodes = Key<Bool>("shouldShowMissingEpisodes", default: true, suite: .generalSuite)
        static let similarPosterType = Key<PosterType>("similarPosterType", default: .portrait, suite: .generalSuite)

        // TODO: have search poster type by types of items if applicable
        static let searchPosterType = Key<PosterType>("searchPosterType", default: .portrait, suite: .generalSuite)

        enum CinematicItemViewType {

            static let usePrimaryImage: Key<Bool> = .init("cinematicItemViewTypeUsePrimaryImage", default: false, suite: .generalSuite)
        }

        enum Episodes {

            static let useSeriesLandscapeBackdrop = Key<Bool>("useSeriesBackdrop", default: true, suite: .generalSuite)
        }

        enum Indicators {

            static let showFavorited: Key<Bool> = .init("showFavoritedIndicator", default: true, suite: .generalSuite)
            static let showProgress: Key<Bool> = .init("showProgressIndicator", default: true, suite: .generalSuite)
            static let showUnplayed: Key<Bool> = .init("showUnplayedIndicator", default: true, suite: .generalSuite)
            static let showPlayed: Key<Bool> = .init("showPlayedIndicator", default: true, suite: .generalSuite)
        }

        enum Library {

            static let cinematicBackground: Key<Bool> = .init(
                "Customization.Library.cinematicBackground",
                default: true,
                suite: .generalSuite
            )
            static let enabledDrawerFilters: Key<[ItemFilterType]> = .init(
                "Library.enabledDrawerFilters",
                default: ItemFilterType.allCases,
                suite: .generalSuite
            )
            static let viewType = Key<LibraryViewType>(
                "libraryViewType",
                default: .grid,
                suite: .generalSuite
            )
            static let posterType = Key<PosterType>(
                "libraryPosterType",
                default: .portrait,
                suite: .generalSuite
            )
            static let listColumnCount = Key<Int>(
                "listColumnCount",
                default: 1,
                suite: .generalSuite
            )
            static let randomImage: Key<Bool> = .init(
                "libraryRandomImage",
                default: true,
                suite: .generalSuite
            )
            static let showFavorites: Key<Bool> = .init(
                "libraryShowFavorites",
                default: true,
                suite: .generalSuite
            )
        }

        enum Search {

            static let enabledDrawerFilters: Key<[ItemFilterType]> = .init(
                "Search.enabledDrawerFilters",
                default: ItemFilterType.allCases,
                suite: .generalSuite
            )
        }
    }

    enum VideoPlayer {

        static let autoPlayEnabled: Key<Bool> = .init("autoPlayEnabled", default: true, suite: .generalSuite)
        static let barActionButtons: Key<[VideoPlayerActionButton]> = .init(
            "barActionButtons",
            default: VideoPlayerActionButton.defaultBarActionButtons,
            suite: .generalSuite
        )
        static let jumpBackwardLength: Key<VideoPlayerJumpLength> = .init(
            "jumpBackwardLength",
            default: .fifteen,
            suite: .generalSuite
        )
        static let jumpForwardLength: Key<VideoPlayerJumpLength> = .init(
            "jumpForwardLength",
            default: .fifteen,
            suite: .generalSuite
        )
        static let menuActionButtons: Key<[VideoPlayerActionButton]> = .init(
            "menuActionButtons",
            default: VideoPlayerActionButton.defaultMenuActionButtons,
            suite: .generalSuite
        )
        static let resumeOffset: Key<Int> = .init("resumeOffset", default: 0, suite: .generalSuite)
        static let showJumpButtons: Key<Bool> = .init("showJumpButtons", default: true, suite: .generalSuite)
        static let videoPlayerType: Key<VideoPlayerType> = .init("videoPlayerType", default: .swiftfin, suite: .generalSuite)

        enum Gesture {

            static let horizontalPanGesture: Key<PanAction> = .init(
                "videoPlayerHorizontalPanGesture",
                default: .none,
                suite: .generalSuite
            )
            static let horizontalSwipeGesture: Key<SwipeAction> = .init(
                "videoPlayerHorizontalSwipeGesture",
                default: .none,
                suite: .generalSuite
            )
            static let longPressGesture: Key<LongPressAction> = .init(
                "videoPlayerLongPressGesture",
                default: .gestureLock,
                suite: .generalSuite
            )
            static let multiTapGesture: Key<MultiTapAction> = .init("videoPlayerMultiTapGesture", default: .none, suite: .generalSuite)
            static let doubleTouchGesture: Key<DoubleTouchAction> = .init(
                "videoPlayerDoubleTouchGesture",
                default: .none,
                suite: .generalSuite
            )
            static let pinchGesture: Key<PinchAction> = .init("videoPlayerSwipeGesture", default: .aspectFill, suite: .generalSuite)
            static let verticalPanGestureLeft: Key<PanAction> = .init(
                "videoPlayerVerticalPanGestureLeft",
                default: .none,
                suite: .generalSuite
            )
            static let verticalPanGestureRight: Key<PanAction> = .init(
                "videoPlayerVerticalPanGestureRight",
                default: .none,
                suite: .generalSuite
            )
        }

        enum Overlay {

            static let chapterSlider: Key<Bool> = .init("chapterSlider", default: true, suite: .generalSuite)
            static let playbackButtonType: Key<PlaybackButtonType> = .init(
                "videoPlayerPlaybackButtonLocation",
                default: .large,
                suite: .generalSuite
            )
            static let sliderColor: Key<Color> = .init("sliderColor", default: Color.white, suite: .generalSuite)
            static let sliderType: Key<SliderType> = .init("sliderType", default: .capsule, suite: .generalSuite)

            // Timestamp
            static let trailingTimestampType: Key<TrailingTimestampType> = .init(
                "trailingTimestamp",
                default: .timeLeft,
                suite: .generalSuite
            )
            static let showCurrentTimeWhileScrubbing: Key<Bool> = .init(
                "showCurrentTimeWhileScrubbing",
                default: true,
                suite: .generalSuite
            )
            static let timestampType: Key<TimestampType> = .init("timestampType", default: .split, suite: .generalSuite)
        }

        enum Subtitle {

            static let subtitleColor: Key<Color> = .init(
                "subtitleColor",
                default: .white,
                suite: .generalSuite
            )
            static let subtitleFontName: Key<String> = .init(
                "subtitleFontName",
                default: UIFont.systemFont(ofSize: 14).fontName,
                suite: .generalSuite
            )
            static let subtitleSize: Key<Int> = .init("subtitleSize", default: 16, suite: .generalSuite)
        }

        enum Transition {
            static let pauseOnBackground: Key<Bool> = .init("pauseOnBackground", default: false, suite: .generalSuite)
            static let playOnActive: Key<Bool> = .init("playOnActive", default: false, suite: .generalSuite)
        }
    }

    // Experimental settings
    enum Experimental {

        static let downloads: Key<Bool> = .init("experimentalDownloads", default: false, suite: .generalSuite)
        static let syncSubtitleStateWithAdjacent = Key<Bool>(
            "experimentalSyncSubtitleState",
            default: false,
            suite: .generalSuite
        )
        static let forceDirectPlay = Key<Bool>("forceDirectPlay", default: false, suite: .generalSuite)

        static let liveTVForceDirectPlay = Key<Bool>("liveTVForceDirectPlay", default: false, suite: .generalSuite)
    }

    // tvos specific
    static let downActionShowsMenu = Key<Bool>("downActionShowsMenu", default: true, suite: .generalSuite)
    static let confirmClose = Key<Bool>("confirmClose", default: false, suite: .generalSuite)
}

// MARK: Debug

#if DEBUG

extension UserDefaults {

    static let debugSuite = UserDefaults(suiteName: "swiftfinstore-debug-defaults")!
}

extension Defaults.Keys {

    static let sendProgressReports: Key<Bool> = .init("sendProgressReports", default: true, suite: .debugSuite)
}
#endif
