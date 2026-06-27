//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
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
    static let appSuite = UserDefaults(suiteName: "guamaflixApp")!

    // MARK: User

    static var currentUserSuite: UserDefaults {
        switch Defaults[.lastSignedInUserID] {
        case .signedOut:
            userSuite(id: "default")
        case let .signedIn(userID):
            userSuite(id: userID)
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
    static var accentColor: Key<Color> = AppKey("accentColor", default: .white)

    /// The _real_ appearance key to be used.
    ///
    /// This is set externally whenever the app or user appearances change,
    /// depending on the current app state.
    static let appearance: Key<AppAppearance> = AppKey("appearance", default: .system)

    /// The appearance default for non-user contexts.
    /// /// Only use for `set`, use `appearance` for `get`.
    static let appAppearance: Key<AppAppearance> = AppKey("appAppearance", default: .system)

    static let backgroundSignOutInterval: Key<TimeInterval> = AppKey("backgroundSignOutInterval", default: 3600)
    static let backgroundTimeStamp: Key<Date> = AppKey("backgroundTimeStamp", default: Date.now)
    static let lastSignedInUserID: Key<UserSignInState> = AppKey("lastSignedInUserID", default: .signedOut)

    static let selectUserDisplayType: Key<LibraryDisplayType> = AppKey("selectUserDisplayType", default: .grid)
    static let selectUserServerSelection: Key<SelectUserServerSelection> = AppKey("selectUserServerSelection", default: .all)
    static let selectUserSortOrder: Key<SelectUserSortOrder> = AppKey("selectUserSortOrder", default: .name)
    static let selectUserAllServersSplashscreen: Key<SelectUserServerSelection> = AppKey("selectUserAllServersSplashscreen", default: .all)
    static let selectUserUseSplashscreen: Key<Bool> = AppKey("selectUserUseSplashscreen", default: true)

    static let signOutOnBackground: Key<Bool> = AppKey("signOutOnBackground", default: true)
    static let signOutOnClose: Key<Bool> = AppKey("signOutOnClose", default: false)
}

// MARK: User

extension Defaults.Keys {

    /// The accent color default for user contexts.
    /// Only use for `set`, use `accentColor` for `get`.
    static var userAccentColor: Key<Color> {
        UserKey("userAccentColor", default: .white)
    }

    /// The appearance default for user contexts.
    /// /// Only use for `set`, use `appearance` for `get`.
    static var userAppearance: Key<AppAppearance> {
        UserKey("userAppearance", default: .system)
    }

    enum Customization {

        static var itemViewType: Key<ItemViewType> {
            UserKey("itemViewType", default: .compactLogo)
        }

        static var showPosterLabels: Key<Bool> {
            UserKey("showPosterLabels", default: true)
        }

        static var nextUpPosterType: Key<PosterDisplayType> {
            UserKey("nextUpPosterType", default: .portrait)
        }

        static var recentlyAddedPosterType: Key<PosterDisplayType> {
            UserKey("recentlyAddedPosterType", default: .portrait)
        }

        static var latestInLibraryPosterType: Key<PosterDisplayType> {
            UserKey("latestInLibraryPosterType", default: .portrait)
        }

        static var shouldShowMissingSeasons: Key<Bool> {
            UserKey("shouldShowMissingSeasons", default: true)
        }

        static var shouldShowMissingEpisodes: Key<Bool> {
            UserKey("shouldShowMissingEpisodes", default: true)
        }

        static var similarPosterType: Key<PosterDisplayType> {
            UserKey("similarPosterType", default: .portrait)
        }

        // TODO: have search poster type by types of items if applicable
        static var searchPosterType: Key<PosterDisplayType> {
            UserKey("searchPosterType", default: .portrait)
        }

        enum CinematicItemViewType {

            static var usePrimaryImage: Key<Bool> {
                UserKey("cinematicItemViewTypeUsePrimaryImage", default: false)
            }
        }

        enum Episodes {

            static var useSeriesLandscapeBackdrop: Key<Bool> {
                UserKey("useSeriesBackdrop", default: true)
            }
        }

        enum Indicators {

            static var showFavorited: Key<Bool> {
                UserKey("showFavoritedIndicator", default: true)
            }

            static var showProgress: Key<Bool> {
                UserKey("showProgressIndicator", default: true)
            }

            static var showUnplayed: Key<UnplayedIndicatorType> {
                UserKey("showUnplayedIndicator", default: .indicator)
            }

            static var showPlayed: Key<Bool> {
                UserKey("showPlayedIndicator", default: true)
            }
        }

        enum Library {

            static var cinematicBackground: Key<Bool> {
                UserKey("libraryCinematicBackground", default: true)
            }

            static var enabledDrawerFilters: Key<[ItemFilterType]> {
                UserKey(
                    "libraryEnabledDrawerFilters",
                    default: ItemFilterType.allCases
                )
            }

            static var letterPickerOrientation: Key<LetterPickerOrientation> {
                UserKey("letterPickerOrientation", default: .disabled)
            }

            static var displayType: Key<LibraryDisplayType> {
                UserKey("libraryViewType", default: .grid)
            }

            static var posterType: Key<PosterDisplayType> {
                UserKey("libraryPosterType", default: .portrait)
            }

            static var listColumnCount: Key<Int> {
                UserKey("listColumnCount", default: 1)
            }

            static var randomImage: Key<Bool> {
                UserKey("libraryRandomImage", default: true)
            }

            static var showFavorites: Key<Bool> {
                UserKey("libraryShowFavorites", default: true)
            }

            static var rememberLayout: Key<Bool> {
                UserKey("libraryRememberLayout", default: false)
            }

            static var rememberSort: Key<Bool> {
                UserKey("libraryRememberSort", default: false)
            }
        }

        enum Home {
            static var showRecentlyAdded: Key<Bool> {
                UserKey("showRecentlyAdded", default: true)
            }

            static var resumeNextUp: Key<Bool> {
                UserKey("homeResumeNextUp", default: false)
            }

            static var maxNextUp: Key<TimeInterval> {
                UserKey(
                    "homeMaxNextUp",
                    default: 366 * 86400
                )
            }
        }

        enum Search {

            static var enabledDrawerFilters: Key<[ItemFilterType]> {
                UserKey(
                    "searchEnabledDrawerFilters",
                    default: ItemFilterType.allCases
                )
            }
        }
    }

    enum VideoPlayer {

        // Legacy alias — shares the same storage id as `Playback.appMaximumBitrate` below. Kept in sync
        // so reads through either path resolve to the same default. `.max` = the 20 Mbps ceiling (see
        // `PlaybackBitrate.ceiling`): Direct Play up to 20 Mbps, transcode only above it.
        static var appMaximumBitrate: Key<PlaybackBitrate> {
            UserKey("appMaximumBitrate", default: .max)
        }

        static var appMaximumBitrateTest: Key<PlaybackBitrateTestSize> {
            UserKey("appMaximumBitrateTest", default: .regular)
        }

        static var autoPlayEnabled: Key<Bool> {
            UserKey("autoPlayEnabled", default: true)
        }

        static var barActionButtons: Key<[VideoPlayerActionButton]> {
            UserKey(
                "barActionButtons",
                default: VideoPlayerActionButton.defaultBarActionButtons
            )
        }

        static var jumpBackwardInterval: Key<MediaJumpInterval> {
            UserKey("jumpBackwardLength", default: .fifteen)
        }

        static var jumpForwardInterval: Key<MediaJumpInterval> {
            UserKey("jumpForwardLength", default: .fifteen)
        }

        static var menuActionButtons: Key<[VideoPlayerActionButton]> {
            UserKey(
                "menuActionButtons",
                default: VideoPlayerActionButton.defaultMenuActionButtons
            )
        }

        static var resumeOffset: Key<Int> {
            UserKey("resumeOffset", default: 0)
        }

        static var supplements: Key<[VideoPlayerSupplement]> {
            UserKey(
                "videoPlayerSupplements",
                default: VideoPlayerSupplement.supportedCases
            )
        }

        static var videoPlayerType: Key<VideoPlayerType> {
            UserKey("videoPlayerType", default: .swiftfin)
        }

        enum Gesture {

            static var horizontalPanAction: Key<PanGestureAction> {
                UserKey("videoPlayerHorizontalPanGesture", default: .none)
            }

            static var horizontalSwipeAction: Key<SwipeGestureAction> {
                UserKey("videoPlayerhorizontalSwipeAction", default: .none)
            }

            static var longPressAction: Key<LongPressGestureAction> {
                UserKey("videoPlayerLongPressGesture", default: .gestureLock)
            }

            static var longPressSpeedMultiplier: Key<PlaybackSpeed> {
                UserKey(
                    "videoPlayerLongPressSpeedMultiplier",
                    default: .two
                )
            }

            static var multiTapGesture: Key<MultiTapGestureAction> {
                UserKey("videoPlayerMultiTapGesture", default: .none)
            }

            static var doubleTouchGesture: Key<DoubleTouchGestureAction> {
                UserKey("videoPlayerDoubleTouchGesture", default: .none)
            }

            static var pinchGesture: Key<PinchGestureAction> {
                UserKey("videoPlayerSwipeGesture", default: .aspectFill)
            }

            static var verticalPanLeftAction: Key<PanGestureAction> {
                UserKey("videoPlayerverticalPanLeftAction", default: .none)
            }

            static var verticalPanRightAction: Key<PanGestureAction> {
                UserKey("videoPlayerverticalPanRightAction", default: .none)
            }
        }

        enum Overlay {

            static var chapterSlider: Key<Bool> {
                UserKey("chapterSlider", default: true)
            }

            // Timestamp
            static var trailingTimestampType: Key<TrailingTimestampType> {
                UserKey("trailingTimestamp", default: .timeLeft)
            }
        }

        enum Playback {
            // Default to a 20 Mbps cap — a near-transparent 4K-HDR HEVC streaming bitrate. This is the
            // sweet spot between the two failure modes we hit: `.auto` ran a per-play speed test (latency)
            // AND tone-mapped HDR→SDR; `.max` (no cap) Direct Played the full ~50–100 Mbps remux, which the
            // network couldn't sustain → stutter. A fixed cap asks the server to transcode down in bitrate
            // ONLY — the native device profile advertises the HDR range types (see `VideoPlayerType+Native`
            // `nativeHDRProfiles`), so the HEVC→HEVC transcode KEEPS the dynamic range (no SDR tone-map) and
            // no speed test runs. `.max` is the 20 Mbps app ceiling (`PlaybackBitrate.ceiling`): Direct Play
            // up to 20 Mbps, transcode only above. Users can lower it in Settings → Video Player → Maximum
            // Bitrate.
            static var appMaximumBitrate: Key<PlaybackBitrate> {
                UserKey("appMaximumBitrate", default: .max)
            }

            static var appMaximumBitrateTest: Key<PlaybackBitrateTestSize> {
                UserKey("appMaximumBitrateTest", default: .regular)
            }

            static var compatibilityMode: Key<PlaybackCompatibility> {
                UserKey("compatibilityMode", default: .auto)
            }

            static var customDeviceProfileAction: Key<CustomDeviceProfileAction> {
                UserKey("customDeviceProfileAction", default: .add)
            }

            static var rates: Key<[Float]> {
                UserKey("videoPlayerPlaybackRates", default: [0.5, 1.0, 1.25, 1.5, 2.0])
            }

            static var playbackRate: Key<Float> {
                UserKey("playbackRate", default: Float(1.0))
            }
        }

        // TODO: transition into a SubtitleConfiguration instead of multiple types
        enum Subtitle {

            static var subtitleColor: Key<Color> {
                UserKey("subtitleColor", default: .white)
            }

            static var subtitleFontName: Key<String> {
                UserKey("subtitleFontName", default: UIFont.systemFont(ofSize: 14).fontName)
            }

            static var subtitleSize: Key<Int> {
                UserKey("subtitleSize", default: 9)
            }
        }

        enum Transition {
            static var pauseOnBackground: Key<Bool> {
                UserKey("playInBackground", default: true)
            }
        }
    }

    // Experimental settings
    enum Experimental {

        static var downloads: Key<Bool> {
            UserKey("experimentalDownloads", default: false)
        }

        static var serverConnectionAutoSwitch: Key<Bool> {
            UserKey("experimentalServerConnectionAutoSwitch", default: false)
        }
    }

    // tvos specific

    static var confirmClose: Key<Bool> {
        UserKey("confirmClose", default: false)
    }
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

    static let isLiquidGlassEnabled: Key<Bool> = DebugKey("experimentalLiquidGlass", default: false)
    static let sendProgressReports: Key<Bool> = DebugKey("sendProgressReports", default: true)
}
#else
extension Defaults.Keys {
    static let isLiquidGlassEnabled: Key<Bool> = AppKey("experimentalLiquidGlass", default: false)
}
#endif
