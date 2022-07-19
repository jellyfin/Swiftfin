//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
	/// About
	internal static var about: String { L10n.tr("Localizable", "about") }
	/// Accessibility
	internal static var accessibility: String { L10n.tr("Localizable", "accessibility") }
	/// Add URL
	internal static var addURL: String { L10n.tr("Localizable", "addURL") }
	/// Airs %s
	internal static func airWithDate(_ p1: UnsafePointer<CChar>) -> String {
		L10n.tr("Localizable", "airWithDate", p1)
	}

	/// All Genres
	internal static var allGenres: String { L10n.tr("Localizable", "allGenres") }
	/// All Media
	internal static var allMedia: String { L10n.tr("Localizable", "allMedia") }
	/// Appearance
	internal static var appearance: String { L10n.tr("Localizable", "appearance") }
	/// Apply
	internal static var apply: String { L10n.tr("Localizable", "apply") }
	/// Audio
	internal static var audio: String { L10n.tr("Localizable", "audio") }
	/// Audio & Captions
	internal static var audioAndCaptions: String { L10n.tr("Localizable", "audioAndCaptions") }
	/// Audio Track
	internal static var audioTrack: String { L10n.tr("Localizable", "audioTrack") }
	/// Authorize
	internal static var authorize: String { L10n.tr("Localizable", "authorize") }
	/// Auto Play
	internal static var autoPlay: String { L10n.tr("Localizable", "autoPlay") }
	/// Back
	internal static var back: String { L10n.tr("Localizable", "back") }
	/// Cancel
	internal static var cancel: String { L10n.tr("Localizable", "cancel") }
	/// Cannot connect to host
	internal static var cannotConnectToHost: String { L10n.tr("Localizable", "cannotConnectToHost") }
	/// CAST
	internal static var cast: String { L10n.tr("Localizable", "cast") }
	/// Cast & Crew
	internal static var castAndCrew: String { L10n.tr("Localizable", "castAndCrew") }
	/// Change Server
	internal static var changeServer: String { L10n.tr("Localizable", "changeServer") }
	/// Channels
	internal static var channels: String { L10n.tr("Localizable", "channels") }
	/// Chapters
	internal static var chapters: String { L10n.tr("Localizable", "chapters") }
	/// Cinematic Views
	internal static var cinematicViews: String { L10n.tr("Localizable", "cinematicViews") }
	/// Close
	internal static var close: String { L10n.tr("Localizable", "close") }
	/// Closed Captions
	internal static var closedCaptions: String { L10n.tr("Localizable", "closedCaptions") }
	/// Compact
	internal static var compact: String { L10n.tr("Localizable", "compact") }
	/// Confirm Close
	internal static var confirmClose: String { L10n.tr("Localizable", "confirmClose") }
	/// Connect
	internal static var connect: String { L10n.tr("Localizable", "connect") }
	/// Connect Manually
	internal static var connectManually: String { L10n.tr("Localizable", "connectManually") }
	/// Connect to Jellyfin
	internal static var connectToJellyfin: String { L10n.tr("Localizable", "connectToJellyfin") }
	/// Connect to a Jellyfin server
	internal static var connectToJellyfinServer: String { L10n.tr("Localizable", "connectToJellyfinServer") }
	/// Connect to a Jellyfin server to get started
	internal static var connectToJellyfinServerStart: String { L10n.tr("Localizable", "connectToJellyfinServerStart") }
	/// Connect to Server
	internal static var connectToServer: String { L10n.tr("Localizable", "connectToServer") }
	/// Containers
	internal static var containers: String { L10n.tr("Localizable", "containers") }
	/// Continue
	internal static var `continue`: String { L10n.tr("Localizable", "continue") }
	/// Continue Watching
	internal static var continueWatching: String { L10n.tr("Localizable", "continueWatching") }
	/// Current Position
	internal static var currentPosition: String { L10n.tr("Localizable", "currentPosition") }
	/// Customize
	internal static var customize: String { L10n.tr("Localizable", "customize") }
	/// Dark
	internal static var dark: String { L10n.tr("Localizable", "dark") }
	/// Default Scheme
	internal static var defaultScheme: String { L10n.tr("Localizable", "defaultScheme") }
	/// DIRECTOR
	internal static var director: String { L10n.tr("Localizable", "director") }
	/// Discovered Servers
	internal static var discoveredServers: String { L10n.tr("Localizable", "discoveredServers") }
	/// Display order
	internal static var displayOrder: String { L10n.tr("Localizable", "displayOrder") }
	/// Edit Jump Lengths
	internal static var editJumpLengths: String { L10n.tr("Localizable", "editJumpLengths") }
	/// Empty Next Up
	internal static var emptyNextUp: String { L10n.tr("Localizable", "emptyNextUp") }
	/// Episode %2$@
	internal static func episode(_ p1: Any) -> String {
		L10n.tr("Localizable", "episode", String(describing: p1))
	}

	/// Episodes
	internal static var episodes: String { L10n.tr("Localizable", "episodes") }
	/// Error
	internal static var error: String { L10n.tr("Localizable", "error") }
	/// Existing Server
	internal static var existingServer: String { L10n.tr("Localizable", "existingServer") }
	/// Existing User
	internal static var existingUser: String { L10n.tr("Localizable", "existingUser") }
	/// Experimental
	internal static var experimental: String { L10n.tr("Localizable", "experimental") }
	/// Favorites
	internal static var favorites: String { L10n.tr("Localizable", "favorites") }
	/// File
	internal static var file: String { L10n.tr("Localizable", "file") }
	/// Filter Results
	internal static var filterResults: String { L10n.tr("Localizable", "filterResults") }
	/// Filters
	internal static var filters: String { L10n.tr("Localizable", "filters") }
	/// Genres
	internal static var genres: String { L10n.tr("Localizable", "genres") }
	/// Home
	internal static var home: String { L10n.tr("Localizable", "home") }
	/// Information
	internal static var information: String { L10n.tr("Localizable", "information") }
	/// Items
	internal static var items: String { L10n.tr("Localizable", "items") }
	/// Jump Backward
	internal static var jumpBackward: String { L10n.tr("Localizable", "jumpBackward") }
	/// Jump Backward Length
	internal static var jumpBackwardLength: String { L10n.tr("Localizable", "jumpBackwardLength") }
	/// Jump Forward
	internal static var jumpForward: String { L10n.tr("Localizable", "jumpForward") }
	/// Jump Forward Length
	internal static var jumpForwardLength: String { L10n.tr("Localizable", "jumpForwardLength") }
	/// Jump Gestures Enabled
	internal static var jumpGesturesEnabled: String { L10n.tr("Localizable", "jumpGesturesEnabled") }
	/// %s seconds
	internal static func jumpLengthSeconds(_ p1: UnsafePointer<CChar>) -> String {
		L10n.tr("Localizable", "jumpLengthSeconds", p1)
	}

	/// Larger
	internal static var larger: String { L10n.tr("Localizable", "larger") }
	/// Largest
	internal static var largest: String { L10n.tr("Localizable", "largest") }
	/// Latest %@
	internal static func latestWithString(_ p1: Any) -> String {
		L10n.tr("Localizable", "latestWithString", String(describing: p1))
	}

	/// Library
	internal static var library: String { L10n.tr("Localizable", "library") }
	/// Light
	internal static var light: String { L10n.tr("Localizable", "light") }
	/// Loading
	internal static var loading: String { L10n.tr("Localizable", "loading") }
	/// Local Servers
	internal static var localServers: String { L10n.tr("Localizable", "localServers") }
	/// Login
	internal static var login: String { L10n.tr("Localizable", "login") }
	/// Login to %@
	internal static func loginToWithString(_ p1: Any) -> String {
		L10n.tr("Localizable", "loginToWithString", String(describing: p1))
	}

	/// Media
	internal static var media: String { L10n.tr("Localizable", "media") }
	/// Missing
	internal static var missing: String { L10n.tr("Localizable", "missing") }
	/// Missing Items
	internal static var missingItems: String { L10n.tr("Localizable", "missingItems") }
	/// More Like This
	internal static var moreLikeThis: String { L10n.tr("Localizable", "moreLikeThis") }
	/// Movies
	internal static var movies: String { L10n.tr("Localizable", "movies") }
	/// %d users
	internal static func multipleUsers(_ p1: Int) -> String {
		L10n.tr("Localizable", "multipleUsers", p1)
	}

	/// Name
	internal static var name: String { L10n.tr("Localizable", "name") }
	/// Networking
	internal static var networking: String { L10n.tr("Localizable", "networking") }
	/// Network timed out
	internal static var networkTimedOut: String { L10n.tr("Localizable", "networkTimedOut") }
	/// Next
	internal static var next: String { L10n.tr("Localizable", "next") }
	/// Next Item
	internal static var nextItem: String { L10n.tr("Localizable", "nextItem") }
	/// Next Up
	internal static var nextUp: String { L10n.tr("Localizable", "nextUp") }
	/// No Cast devices found..
	internal static var noCastdevicesfound: String { L10n.tr("Localizable", "noCastdevicesfound") }
	/// No Codec
	internal static var noCodec: String { L10n.tr("Localizable", "noCodec") }
	/// No episodes available
	internal static var noEpisodesAvailable: String { L10n.tr("Localizable", "noEpisodesAvailable") }
	/// No local servers found
	internal static var noLocalServersFound: String { L10n.tr("Localizable", "noLocalServersFound") }
	/// None
	internal static var none: String { L10n.tr("Localizable", "none") }
	/// No overview available
	internal static var noOverviewAvailable: String { L10n.tr("Localizable", "noOverviewAvailable") }
	/// No public Users
	internal static var noPublicUsers: String { L10n.tr("Localizable", "noPublicUsers") }
	/// No results.
	internal static var noResults: String { L10n.tr("Localizable", "noResults") }
	/// Normal
	internal static var normal: String { L10n.tr("Localizable", "normal") }
	/// N/A
	internal static var notAvailableSlash: String { L10n.tr("Localizable", "notAvailableSlash") }
	/// Type: %@ not implemented yet :(
	internal static func notImplementedYetWithType(_ p1: Any) -> String {
		L10n.tr("Localizable", "notImplementedYetWithType", String(describing: p1))
	}

	/// No title
	internal static var noTitle: String { L10n.tr("Localizable", "noTitle") }
	/// Ok
	internal static var ok: String { L10n.tr("Localizable", "ok") }
	/// 1 user
	internal static var oneUser: String { L10n.tr("Localizable", "oneUser") }
	/// Operating System
	internal static var operatingSystem: String { L10n.tr("Localizable", "operatingSystem") }
	/// Other
	internal static var other: String { L10n.tr("Localizable", "other") }
	/// Other User
	internal static var otherUser: String { L10n.tr("Localizable", "otherUser") }
	/// Overlay
	internal static var overlay: String { L10n.tr("Localizable", "overlay") }
	/// Overlay Type
	internal static var overlayType: String { L10n.tr("Localizable", "overlayType") }
	/// Overview
	internal static var overview: String { L10n.tr("Localizable", "overview") }
	/// Page %1$@ of %2$@
	internal static func pageOfWithNumbers(_ p1: Any, _ p2: Any) -> String {
		L10n.tr("Localizable", "pageOfWithNumbers", String(describing: p1), String(describing: p2))
	}

	/// Password
	internal static var password: String { L10n.tr("Localizable", "password") }
	/// Play
	internal static var play: String { L10n.tr("Localizable", "play") }
	/// Play / Pause
	internal static var playAndPause: String { L10n.tr("Localizable", "playAndPause") }
	/// Playback settings
	internal static var playbackSettings: String { L10n.tr("Localizable", "playbackSettings") }
	/// Playback Speed
	internal static var playbackSpeed: String { L10n.tr("Localizable", "playbackSpeed") }
	/// Player Gestures Lock Gesture Enabled
	internal static var playerGesturesLockGestureEnabled: String { L10n.tr("Localizable", "playerGesturesLockGestureEnabled") }
	/// Play From Beginning
	internal static var playFromBeginning: String { L10n.tr("Localizable", "playFromBeginning") }
	/// Play Next
	internal static var playNext: String { L10n.tr("Localizable", "playNext") }
	/// Play Next Item
	internal static var playNextItem: String { L10n.tr("Localizable", "playNextItem") }
	/// Play Previous Item
	internal static var playPreviousItem: String { L10n.tr("Localizable", "playPreviousItem") }
	/// Present
	internal static var present: String { L10n.tr("Localizable", "present") }
	/// Press Down for Menu
	internal static var pressDownForMenu: String { L10n.tr("Localizable", "pressDownForMenu") }
	/// Previous Item
	internal static var previousItem: String { L10n.tr("Localizable", "previousItem") }
	/// Programs
	internal static var programs: String { L10n.tr("Localizable", "programs") }
	/// Public Users
	internal static var publicUsers: String { L10n.tr("Localizable", "publicUsers") }
	/// Quick Connect
	internal static var quickConnect: String { L10n.tr("Localizable", "quickConnect") }
	/// Quick Connect code
	internal static var quickConnectCode: String { L10n.tr("Localizable", "quickConnectCode") }
	/// Invalid Quick Connect code
	internal static var quickConnectInvalidError: String { L10n.tr("Localizable", "quickConnectInvalidError") }
	/// Authorizing Quick Connect successful. Please continue on your other device.
	internal static var quickConnectSuccessMessage: String { L10n.tr("Localizable", "quickConnectSuccessMessage") }
	/// Rated
	internal static var rated: String { L10n.tr("Localizable", "rated") }
	/// Recently Added
	internal static var recentlyAdded: String { L10n.tr("Localizable", "recentlyAdded") }
	/// Recommended
	internal static var recommended: String { L10n.tr("Localizable", "recommended") }
	/// Refresh
	internal static var refresh: String { L10n.tr("Localizable", "refresh") }
	/// Regular
	internal static var regular: String { L10n.tr("Localizable", "regular") }
	/// Released
	internal static var released: String { L10n.tr("Localizable", "released") }
	/// Remaining Time
	internal static var remainingTime: String { L10n.tr("Localizable", "remainingTime") }
	/// Remove
	internal static var remove: String { L10n.tr("Localizable", "remove") }
	/// Remove All Users
	internal static var removeAllUsers: String { L10n.tr("Localizable", "removeAllUsers") }
	/// Remove From Resume
	internal static var removeFromResume: String { L10n.tr("Localizable", "removeFromResume") }
	/// Report an Issue
	internal static var reportIssue: String { L10n.tr("Localizable", "reportIssue") }
	/// Request a Feature
	internal static var requestFeature: String { L10n.tr("Localizable", "requestFeature") }
	/// Reset
	internal static var reset: String { L10n.tr("Localizable", "reset") }
	/// Reset App Settings
	internal static var resetAppSettings: String { L10n.tr("Localizable", "resetAppSettings") }
	/// Reset User Settings
	internal static var resetUserSettings: String { L10n.tr("Localizable", "resetUserSettings") }
	/// Resume 5 Second Offset
	internal static var resume5SecondOffset: String { L10n.tr("Localizable", "resume5SecondOffset") }
	/// Retry
	internal static var retry: String { L10n.tr("Localizable", "retry") }
	/// Runtime
	internal static var runtime: String { L10n.tr("Localizable", "runtime") }
	/// Search
	internal static var search: String { L10n.tr("Localizable", "search") }
	/// Search…
	internal static var searchDots: String { L10n.tr("Localizable", "searchDots") }
	/// Searching…
	internal static var searchingDots: String { L10n.tr("Localizable", "searchingDots") }
	/// Season
	internal static var season: String { L10n.tr("Localizable", "season") }
	/// S%1$@:E%2$@
	internal static func seasonAndEpisode(_ p1: Any, _ p2: Any) -> String {
		L10n.tr("Localizable", "seasonAndEpisode", String(describing: p1), String(describing: p2))
	}

	/// Seasons
	internal static var seasons: String { L10n.tr("Localizable", "seasons") }
	/// See All
	internal static var seeAll: String { L10n.tr("Localizable", "seeAll") }
	/// Seek Slide Gesture Enabled
	internal static var seekSlideGestureEnabled: String { L10n.tr("Localizable", "seekSlideGestureEnabled") }
	/// See More
	internal static var seeMore: String { L10n.tr("Localizable", "seeMore") }
	/// Select Cast Destination
	internal static var selectCastDestination: String { L10n.tr("Localizable", "selectCastDestination") }
	/// Series
	internal static var series: String { L10n.tr("Localizable", "series") }
	/// Server
	internal static var server: String { L10n.tr("Localizable", "server") }
	/// Server %s is already connected
	internal static func serverAlreadyConnected(_ p1: UnsafePointer<CChar>) -> String {
		L10n.tr("Localizable", "serverAlreadyConnected", p1)
	}

	/// Server %s already exists. Add new URL?
	internal static func serverAlreadyExistsPrompt(_ p1: UnsafePointer<CChar>) -> String {
		L10n.tr("Localizable", "serverAlreadyExistsPrompt", p1)
	}

	/// Server Details
	internal static var serverDetails: String { L10n.tr("Localizable", "serverDetails") }
	/// Server Information
	internal static var serverInformation: String { L10n.tr("Localizable", "serverInformation") }
	/// Servers
	internal static var servers: String { L10n.tr("Localizable", "servers") }
	/// Server URL
	internal static var serverURL: String { L10n.tr("Localizable", "serverURL") }
	/// Settings
	internal static var settings: String { L10n.tr("Localizable", "settings") }
	/// Show Cast & Crew
	internal static var showCastAndCrew: String { L10n.tr("Localizable", "showCastAndCrew") }
	/// Show Chapters Info In Bottom Overlay
	internal static var showChaptersInfoInBottomOverlay: String { L10n.tr("Localizable", "showChaptersInfoInBottomOverlay") }
	/// Flatten Library Items
	internal static var showFlattenView: String { L10n.tr("Localizable", "showFlattenView") }
	/// Show Missing Episodes
	internal static var showMissingEpisodes: String { L10n.tr("Localizable", "showMissingEpisodes") }
	/// Show Missing Seasons
	internal static var showMissingSeasons: String { L10n.tr("Localizable", "showMissingSeasons") }
	/// Show Poster Labels
	internal static var showPosterLabels: String { L10n.tr("Localizable", "showPosterLabels") }
	/// Signed in as %@
	internal static func signedInAsWithString(_ p1: Any) -> String {
		L10n.tr("Localizable", "signedInAsWithString", String(describing: p1))
	}

	/// Sign In
	internal static var signIn: String { L10n.tr("Localizable", "signIn") }
	/// Sign in to get started
	internal static var signInGetStarted: String { L10n.tr("Localizable", "signInGetStarted") }
	/// Sign In to %s
	internal static func signInToServer(_ p1: UnsafePointer<CChar>) -> String {
		L10n.tr("Localizable", "signInToServer", p1)
	}

	/// Smaller
	internal static var smaller: String { L10n.tr("Localizable", "smaller") }
	/// Smallest
	internal static var smallest: String { L10n.tr("Localizable", "smallest") }
	/// Sort by
	internal static var sortBy: String { L10n.tr("Localizable", "sortBy") }
	/// Source Code
	internal static var sourceCode: String { L10n.tr("Localizable", "sourceCode") }
	/// STUDIO
	internal static var studio: String { L10n.tr("Localizable", "studio") }
	/// Studios
	internal static var studios: String { L10n.tr("Localizable", "studios") }
	/// Subtitles
	internal static var subtitles: String { L10n.tr("Localizable", "subtitles") }
	/// Subtitle Size
	internal static var subtitleSize: String { L10n.tr("Localizable", "subtitleSize") }
	/// Suggestions
	internal static var suggestions: String { L10n.tr("Localizable", "suggestions") }
	/// Switch User
	internal static var switchUser: String { L10n.tr("Localizable", "switchUser") }
	/// System
	internal static var system: String { L10n.tr("Localizable", "system") }
	/// System Control Gestures Enabled
	internal static var systemControlGesturesEnabled: String { L10n.tr("Localizable", "systemControlGesturesEnabled") }
	/// Tags
	internal static var tags: String { L10n.tr("Localizable", "tags") }
	/// Too Many Redirects
	internal static var tooManyRedirects: String { L10n.tr("Localizable", "tooManyRedirects") }
	/// Try again
	internal static var tryAgain: String { L10n.tr("Localizable", "tryAgain") }
	/// TV Shows
	internal static var tvShows: String { L10n.tr("Localizable", "tvShows") }
	/// Unable to connect to server
	internal static var unableToConnectServer: String { L10n.tr("Localizable", "unableToConnectServer") }
	/// Unable to find host
	internal static var unableToFindHost: String { L10n.tr("Localizable", "unableToFindHost") }
	/// Unaired
	internal static var unaired: String { L10n.tr("Localizable", "unaired") }
	/// Unauthorized
	internal static var unauthorized: String { L10n.tr("Localizable", "unauthorized") }
	/// Unauthorized user
	internal static var unauthorizedUser: String { L10n.tr("Localizable", "unauthorizedUser") }
	/// Unknown
	internal static var unknown: String { L10n.tr("Localizable", "unknown") }
	/// Unknown Error
	internal static var unknownError: String { L10n.tr("Localizable", "unknownError") }
	/// URL
	internal static var url: String { L10n.tr("Localizable", "url") }
	/// User
	internal static var user: String { L10n.tr("Localizable", "user") }
	/// User %s is already signed in
	internal static func userAlreadySignedIn(_ p1: UnsafePointer<CChar>) -> String {
		L10n.tr("Localizable", "userAlreadySignedIn", p1)
	}

	/// Username
	internal static var username: String { L10n.tr("Localizable", "username") }
	/// Version
	internal static var version: String { L10n.tr("Localizable", "version") }
	/// Video Player
	internal static var videoPlayer: String { L10n.tr("Localizable", "videoPlayer") }
	/// Who's watching?
	internal static var whosWatching: String { L10n.tr("Localizable", "WhosWatching") }
	/// WIP
	internal static var wip: String { L10n.tr("Localizable", "wip") }
	/// Your Favorites
	internal static var yourFavorites: String { L10n.tr("Localizable", "yourFavorites") }
}

// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
	private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
		let format = TranslationService.shared.lookupTranslation(forKey:inTable:)(key, table)
		return String(format: format, locale: Locale.current, arguments: args)
	}
}
