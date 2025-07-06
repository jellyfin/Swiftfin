//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import SwiftUI
import UIKit

// TODO: organize
// TODO: all user settings could be moved to `StoredValues`?

// Note: Only use Defaults for basic single-value settings.
//       For larger data types and collections, use `StoredValue` instead.

// MARK: Suites

extension UserDefaults {

    // MARK: App

    /// Settings that should apply to the app
    static let appSuite = UserDefaults(suiteName: "swiftfinApp")!

    // MARK: Usser

    // TODO: the Factory resolver cannot be used because it would cause freezes, but
    //       the Defaults value should always be in sync with the latest user and what
    //       views properly expect. However, this feels like a hack and should be changed?
    static var currentUserSuite: UserDefaults {
        switch Defaults[.lastSignedInUserID] {
        case .signedOut:
            return userSuite(id: "default")
        case let .signedIn(userID):
            return userSuite(id: userID)
        }
    }

    static func userSuite(id: String) -> UserDefaults {
        UserDefaults(suiteName: id)!
    }
}

private extension Defaults.Keys {

    static func AppKey<Value: Defaults.Serializable>(_ name: String) -> Key<Value?> {
        Key(name, suite: .appSuite)
    }

    static func AppKey<Value: Defaults.Serializable>(_ name: String, default: Value) -> Key<Value> {
        Key(name, default: `default`, suite: .appSuite)
    }

    static func UserKey<Value: Defaults.Serializable>(_ name: String, default: Value) -> Key<Value> {
        Key(name, default: `default`, suite: .currentUserSuite)
    }
}

// MARK: App

extension Defaults.Keys {

    /// The _real_ accent color key to be used.
    ///
    /// This is set externally whenever the app or user accent colors change,
    /// depending on the current app state.
    static var accentColor: Key<Color> = AppKey("accentColor", default: .jellyfinPurple)

    /// The _real_ appearance key to be used.
    ///
    /// This is set externally whenever the app or user appearances change,
    /// depending on the current app state.
    static let appearance: Key<AppAppearance> = AppKey("appearance", default: .system)

    /// The accent color default for non-user contexts.
    /// Only use for `set`, use `accentColor` for `get`.
    static let appAccentColor: Key<Color> = AppKey("appAccentColor", default: .jellyfinPurple)

    /// The appearance default for non-user contexts.
    /// /// Only use for `set`, use `appearance` for `get`.
    static let appAppearance: Key<AppAppearance> = AppKey("appAppearance", default: .system)

    static let backgroundSignOutInterval: Key<TimeInterval> = AppKey("backgroundSignOutInterval", default: 3600)
    static let backgroundTimeStamp: Key<Date> = AppKey("backgroundTimeStamp", default: Date.now)
    static let lastSignedInUserID: Key<UserSignInState> = AppKey("lastSignedInUserID", default: .signedOut)
    static let defaultUserID: Key<UserSignInState> = AppKey("defaultUserID", default: .signedOut)

    static let selectUserDisplayType: Key<LibraryDisplayType> = AppKey("selectUserDisplayType", default: .grid)
    static let selectUserServerSelection: Key<SelectUserServerSelection> = AppKey("selectUserServerSelection", default: .all)
    static let selectUserAllServersSplashscreen: Key<SelectUserServerSelection> = AppKey("selectUserAllServersSplashscreen", default: .all)
    static let selectUserUseSplashscreen: Key<Bool> = AppKey("selectUserUseSplashscreen", default: true)

    static let signOutOnBackground: Key<Bool> = AppKey("signOutOnBackground", default: true)
    static let signOutOnClose: Key<Bool> = AppKey("signOutOnClose", default: false)
}

// MARK: User

extension Defaults.Keys {

    /// The accent color default for user contexts.
    /// Only use for `set`, use `accentColor` for `get`.
    static var userAccentColor: Key<Color> { UserKey("userAccentColor", default: .jellyfinPurple) }

    /// The appearance default for user contexts.
    /// /// Only use for `set`, use `appearance` for `get`.
    static var userAppearance: Key<AppAppearance> { UserKey("userAppearance", default: .system) }

    enum Customization {

        static let itemViewType: Key<ItemViewType> = UserKey("itemViewType", default: .compactLogo)

        static let showPosterLabels: Key<Bool> = UserKey("showPosterLabels", default: true)
        static let nextUpPosterType: Key<PosterDisplayType> = UserKey("nextUpPosterType", default: .portrait)
        static let recentlyAddedPosterType: Key<PosterDisplayType> = UserKey("recentlyAddedPosterType", default: .portrait)
        static let latestInLibraryPosterType: Key<PosterDisplayType> = UserKey("latestInLibraryPosterType", default: .portrait)
        static let shouldShowMissingSeasons: Key<Bool> = UserKey("shouldShowMissingSeasons", default: true)
        static let shouldShowMissingEpisodes: Key<Bool> = UserKey("shouldShowMissingEpisodes", default: true)
        static let similarPosterType: Key<PosterDisplayType> = UserKey("similarPosterType", default: .portrait)

        // TODO: have search poster type by types of items if applicable
        static let searchPosterType: Key<PosterDisplayType> = UserKey("searchPosterType", default: .portrait)

        enum CinematicItemViewType {

            static let usePrimaryImage: Key<Bool> = UserKey("cinematicItemViewTypeUsePrimaryImage", default: false)
        }

        enum Episodes {

            static let useSeriesLandscapeBackdrop: Key<Bool> = UserKey("useSeriesBackdrop", default: true)
        }

        enum Indicators {

            static let showFavorited: Key<Bool> = UserKey("showFavoritedIndicator", default: true)
            static let showProgress: Key<Bool> = UserKey("showProgressIndicator", default: true)
            static let showUnplayed: Key<Bool> = UserKey("showUnplayedIndicator", default: true)
            static let showPlayed: Key<Bool> = UserKey("showPlayedIndicator", default: true)
        }

        enum Library {

            static let cinematicBackground: Key<Bool> = UserKey("libraryCinematicBackground", default: true)
            static let enabledDrawerFilters: Key<[ItemFilterType]> = UserKey(
                "libraryEnabledDrawerFilters",
                default: ItemFilterType.allCases
            )
            static let letterPickerEnabled: Key<Bool> = UserKey("letterPickerEnabled", default: false)
            static let letterPickerOrientation: Key<LetterPickerOrientation> = .init(
                "letterPickerOrientation", default: .trailing
            )
            static let displayType: Key<LibraryDisplayType> = UserKey("libraryViewType", default: .grid)
            static let posterType: Key<PosterDisplayType> = UserKey("libraryPosterType", default: .portrait)
            static let listColumnCount: Key<Int> = UserKey("listColumnCount", default: 1)
            static let randomImage: Key<Bool> = UserKey("libraryRandomImage", default: true)
            static let showFavorites: Key<Bool> = UserKey("libraryShowFavorites", default: true)

            static let rememberLayout: Key<Bool> = UserKey("libraryRememberLayout", default: false)
            static let rememberSort: Key<Bool> = UserKey("libraryRememberSort", default: false)
        }

        enum Home {
            static let showRecentlyAdded: Key<Bool> = UserKey("showRecentlyAdded", default: true)
            static let resumeNextUp: Key<Bool> = UserKey("homeResumeNextUp", default: false)
            static let maxNextUp: Key<TimeInterval> = UserKey(
                "homeMaxNextUp",
                default: 366 * 86400
            )
        }

        enum Search {

            static let enabledDrawerFilters: Key<[ItemFilterType]> = UserKey(
                "searchEnabledDrawerFilters",
                default: ItemFilterType.allCases
            )
        }
    }

    enum VideoPlayer {

        static let appMaximumBitrate: Key<PlaybackBitrate> = UserKey("appMaximumBitrate", default: .max)
        static let appMaximumBitrateTest: Key<PlaybackBitrateTestSize> = UserKey("appMaximumBitrateTest", default: .regular)
        static let autoPlayEnabled: Key<Bool> = UserKey("autoPlayEnabled", default: true)
        static let barActionButtons: Key<[VideoPlayerActionButton]> = UserKey(
            "barActionButtons",
            default: VideoPlayerActionButton.defaultBarActionButtons
        )
        static let jumpBackwardLength: Key<VideoPlayerJumpLength> = UserKey("jumpBackwardLength", default: .fifteen)
        static let jumpForwardLength: Key<VideoPlayerJumpLength> = UserKey("jumpForwardLength", default: .fifteen)
        static let menuActionButtons: Key<[VideoPlayerActionButton]> = UserKey(
            "menuActionButtons",
            default: VideoPlayerActionButton.defaultMenuActionButtons
        )
        static let resumeOffset: Key<Int> = UserKey("resumeOffset", default: 0)
        static let showJumpButtons: Key<Bool> = UserKey("showJumpButtons", default: true)
        static let videoPlayerType: Key<VideoPlayerType> = UserKey("videoPlayerType", default: .swiftfin)

        enum Gesture {

            static let horizontalPanGesture: Key<PanAction> = UserKey("videoPlayerHorizontalPanGesture", default: .none)
            static let horizontalSwipeGesture: Key<SwipeAction> = UserKey("videoPlayerHorizontalSwipeGesture", default: .none)
            static let longPressGesture: Key<LongPressAction> = UserKey("videoPlayerLongPressGesture", default: .gestureLock)
            static let multiTapGesture: Key<MultiTapAction> = UserKey("videoPlayerMultiTapGesture", default: .none)
            static let doubleTouchGesture: Key<DoubleTouchAction> = UserKey("videoPlayerDoubleTouchGesture", default: .none)
            static let pinchGesture: Key<PinchAction> = UserKey("videoPlayerSwipeGesture", default: .aspectFill)
            static let verticalPanGestureLeft: Key<PanAction> = UserKey("videoPlayerVerticalPanGestureLeft", default: .none)
            static let verticalPanGestureRight: Key<PanAction> = UserKey("videoPlayerVerticalPanGestureRight", default: .none)
        }

        enum Overlay {

            static let chapterSlider: Key<Bool> = UserKey("chapterSlider", default: true)
            static let playbackButtonType: Key<PlaybackButtonType> = UserKey("videoPlayerPlaybackButtonLocation", default: .large)
            static let sliderColor: Key<Color> = UserKey("sliderColor", default: Color.white)
            static let sliderType: Key<SliderType> = UserKey("sliderType", default: .capsule)

            // Timestamp
            static let trailingTimestampType: Key<TrailingTimestampType> = UserKey("trailingTimestamp", default: .timeLeft)
            static let showCurrentTimeWhileScrubbing: Key<Bool> = UserKey("showCurrentTimeWhileScrubbing", default: true)
            static let timestampType: Key<TimestampType> = UserKey("timestampType", default: .split)
        }

        enum Playback {
            static let appMaximumBitrate: Key<PlaybackBitrate> = UserKey("appMaximumBitrate", default: .auto)
            static let appMaximumBitrateTest: Key<PlaybackBitrateTestSize> = UserKey("appMaximumBitrateTest", default: .regular)
            static let compatibilityMode: Key<PlaybackCompatibility> = UserKey("compatibilityMode", default: .auto)
            static let customDeviceProfileAction: Key<CustomDeviceProfileAction> = UserKey("customDeviceProfileAction", default: .add)
        }

        enum Subtitle {

            static let subtitleColor: Key<Color> = UserKey("subtitleColor", default: .white)
            static let subtitleFontName: Key<String> = UserKey("subtitleFontName", default: UIFont.systemFont(ofSize: 14).fontName)
            static let subtitleSize: Key<Int> = UserKey("subtitleSize", default: 16)
        }

        enum Transition {
            static let pauseOnBackground: Key<Bool> = UserKey("pauseOnBackground", default: false)
            static let playOnActive: Key<Bool> = UserKey("playOnActive", default: false)
        }
    }

    // Experimental settings
    enum Experimental {

        static let downloads: Key<Bool> = UserKey("experimentalDownloads", default: false)
    }

    // tvos specific
    static let downActionShowsMenu: Key<Bool> = UserKey("downActionShowsMenu", default: true)
    static let confirmClose: Key<Bool> = UserKey("confirmClose", default: false)
}

// MARK: Debug

#if DEBUG

extension UserDefaults {

    static let debugSuite = UserDefaults(suiteName: "swiftfinstore-debug-defaults")!
}

extension Defaults.Keys {

    static func DebugKey<Value: Defaults.Serializable>(_ name: String, default: Value) -> Key<Value> {
        Key(name, default: `default`, suite: .appSuite)
    }

    static let sendProgressReports: Key<Bool> = DebugKey("sendProgressReports", default: true)
}
#endif
