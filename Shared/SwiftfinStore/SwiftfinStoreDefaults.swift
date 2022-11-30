//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
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
    static let defaultHTTPScheme = Key<HTTPScheme>("defaultHTTPScheme", default: .http, suite: .universalSuite)
    static let appAppearance = Key<AppAppearance>("appAppearance", default: .system, suite: .universalSuite)

    // General settings
    static let lastServerUserID = Defaults.Key<String?>("lastServerUserID", suite: .generalSuite)
    static let inNetworkBandwidth = Key<Int>("InNetworkBandwidth", default: 40_000_000, suite: .generalSuite)
    static let outOfNetworkBandwidth = Key<Int>("OutOfNetworkBandwidth", default: 40_000_000, suite: .generalSuite)
    static let libraryFilterStore = Key<[String: ItemFilters]>("libraryFilterStore", default: [:], suite: .generalSuite)

    enum Customization {
        static let itemViewType = Key<ItemViewType>("itemViewType", default: .compactLogo, suite: .generalSuite)

        static let showPosterLabels = Key<Bool>("showPosterLabels", default: true, suite: .generalSuite)
        static let nextUpPosterType = Key<PosterType>("nextUpPosterType", default: .portrait, suite: .generalSuite)
        static let recentlyAddedPosterType = Key<PosterType>("recentlyAddedPosterType", default: .portrait, suite: .generalSuite)
        static let latestInLibraryPosterType = Key<PosterType>("latestInLibraryPosterType", default: .portrait, suite: .generalSuite)
        static let similarPosterType = Key<PosterType>("similarPosterType", default: .portrait, suite: .generalSuite)
        static let searchPosterType = Key<PosterType>("searchPosterType", default: .portrait, suite: .generalSuite)

        enum Episodes {
            static let useSeriesLandscapeBackdrop = Key<Bool>("useSeriesBackdrop", default: true, suite: .generalSuite)
        }

        enum Library {
            static let viewType = Key<LibraryViewType>("Customization.Library.viewType", default: .grid, suite: .generalSuite)
            static let gridPosterType = Key<PosterType>("Customization.Library.gridPosterType", default: .portrait, suite: .generalSuite)
        }
    }

    enum VideoPlayer {
        
        // TODO: rename buttons to show_
        // TODO: Add to own suite
        
        static let videoPlayerType: Key<VideoPlayerType> = .init("videoPlayerType", default: .vlc, suite: .generalSuite)

        static let autoPlay: Key<Bool> = .init("autoPlay", default: true, suite: .generalSuite)
        static let autoPlayEnabled: Key<Bool> = .init("autoPlayEnabled", default: true, suite: .generalSuite)
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
        static let playNextItem: Key<Bool> = .init("playNextItem", default: true, suite: .generalSuite)
        static let playPreviousItem: Key<Bool> = .init("playPreviousItem", default: true, suite: .generalSuite)
        static let pauseOnBackgrounded: Key<Bool> = .init("pauseOnBackgrounded", default: true, suite: .generalSuite)
        static let resumeOffset: Key<Int> = .init("resumeOffset", default: 0, suite: .generalSuite)
        
        static let showAspectFill: Key<Bool> = .init("videoPlayer.showAspectFill", default: true, suite: .generalSuite)
        static let showJumpButtons: Key<Bool> = .init("showJumpButtons", default: true, suite: .generalSuite)
        
        static let showAudioTrackMenu: Key<Bool> = .init("showAudioTrackMenu", default: false, suite: .generalSuite)
        static let showPlaybackSpeed: Key<Bool> = .init("showPlaybackSpeed", default: false, suite: .generalSuite)
        static let showSubtitleTrackMenu: Key<Bool> = .init("showSubtitleTrackMenu", default: false, suite: .generalSuite)
        
        enum Gesture {
            static let horizontalPanGesture: Key<PanAction> = .init("videoPlayer.horizontalPanGesture", default: .none, suite: .generalSuite)
            static let horizontalSwipeGesture: Key<SwipeAction> = .init("videoPlayer.horizontalSwipeGesture", default: .none, suite: .generalSuite)
            static let longPressGesture: Key<LongPressAction> = .init("videoPlayer.longPressGesture", default: .gestureLock, suite: .generalSuite)
            static let multiTapGesture: Key<MultiTapAction> = .init("videoPlayer.multiTapGesture", default: .none, suite: .generalSuite)
            static let pinchGesture: Key<PinchAction> = .init("videoPlayer.swipeGesture", default: .aspectFill, suite: .generalSuite)
            static let verticalPanGestureLeft: Key<PanAction> = .init("videoPlayer.verticalPanGestureLeft", default: .none, suite: .generalSuite)
            static let verticalPanGestureRight: Key<PanAction> = .init("videoPlayer.verticalPanGestureRight", default: .none, suite: .generalSuite)
        }

        enum Overlay {

            static let chapterSlider: Key<Bool> = .init("chapterSlider", default: true, suite: .generalSuite)
            static let playbackButtonType: Key<PlaybackButtonType> = .init(
                "VideoPlayer.Overlay.playbackButtonLocation",
                default: .large,
                suite: .generalSuite
            )
            static let sliderColor: Key<Color> = .init("sliderColor", default: Color.white, suite: .generalSuite)
            static let sliderType: Key<SliderType> = .init("sliderType", default: .capsule, suite: .generalSuite)

            // Timestamp
            static let trailingTimestampType: Key<TrailingTimestampType> = .init("trailingTimestamp", default: .timeLeft, suite: .generalSuite)
            static let showCurrentTimeWhileScrubbing: Key<Bool> = .init(
                "showCurrentTimeWhileScrubbing",
                default: true,
                suite: .generalSuite
            )
            static let timestampType: Key<TimestampType> = .init("timestampType", default: .split, suite: .generalSuite)
        }
        
        enum NativePlayer {
            
            static let useFMP4Container: Key<Bool> = .init("nativePlayer.useFMP4Container", default: false, suite: .generalSuite)
        }
        
        enum Subtitle {

            static let subtitleFontName: Key<String> = .init(
                "subtitleFontName",
                default: UIFont.systemFont(ofSize: 14).fontName,
                suite: .generalSuite
            )
            static let subtitleSize: Key<Int> = .init("subtitleSize", default: 16, suite: .generalSuite)
        }
    }

    // Video player / overlay settings
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

    // Should show missing seasons and episodes
    static let shouldShowMissingSeasons = Key<Bool>("shouldShowMissingSeasons", default: true, suite: .generalSuite)
    static let shouldShowMissingEpisodes = Key<Bool>("shouldShowMissingEpisodes", default: true, suite: .generalSuite)

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
        static let lastChapterNextItem: Key<Bool> = .init("lastChapterNextItem", default: false, suite: .generalSuite)
    }

    // tvos specific
    static let downActionShowsMenu = Key<Bool>("downActionShowsMenu", default: true, suite: .generalSuite)
    static let confirmClose = Key<Bool>("confirmClose", default: false, suite: .generalSuite)
}

// MARK: Legacy

// To be removed after their usage is removed

extension Defaults.Keys {

    static let overlayType = Key<OverlayType>("overlayType", default: .normal, suite: .generalSuite)
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
}
