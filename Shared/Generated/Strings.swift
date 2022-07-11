// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// About
  internal static var about: String { return L10n.tr("Localizable", "about") }
  /// Accessibility
  internal static var accessibility: String { return L10n.tr("Localizable", "accessibility") }
  /// Add URL
  internal static var addURL: String { return L10n.tr("Localizable", "addURL") }
  /// Airs %s
  internal static func airWithDate(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "airWithDate", p1)
  }
  /// All Genres
  internal static var allGenres: String { return L10n.tr("Localizable", "allGenres") }
  /// All Media
  internal static var allMedia: String { return L10n.tr("Localizable", "allMedia") }
  /// Appearance
  internal static var appearance: String { return L10n.tr("Localizable", "appearance") }
  /// Apply
  internal static var apply: String { return L10n.tr("Localizable", "apply") }
  /// Audio
  internal static var audio: String { return L10n.tr("Localizable", "audio") }
  /// Audio & Captions
  internal static var audioAndCaptions: String { return L10n.tr("Localizable", "audioAndCaptions") }
  /// Audio Track
  internal static var audioTrack: String { return L10n.tr("Localizable", "audioTrack") }
  /// Auto Play
  internal static var autoPlay: String { return L10n.tr("Localizable", "autoPlay") }
  /// Back
  internal static var back: String { return L10n.tr("Localizable", "back") }
  /// Cancel
  internal static var cancel: String { return L10n.tr("Localizable", "cancel") }
  /// Cannot connect to host
  internal static var cannotConnectToHost: String { return L10n.tr("Localizable", "cannotConnectToHost") }
  /// CAST
  internal static var cast: String { return L10n.tr("Localizable", "cast") }
  /// Cast & Crew
  internal static var castAndCrew: String { return L10n.tr("Localizable", "castAndCrew") }
  /// Change Server
  internal static var changeServer: String { return L10n.tr("Localizable", "changeServer") }
  /// Channels
  internal static var channels: String { return L10n.tr("Localizable", "channels") }
  /// Chapters
  internal static var chapters: String { return L10n.tr("Localizable", "chapters") }
  /// Cinematic Views
  internal static var cinematicViews: String { return L10n.tr("Localizable", "cinematicViews") }
  /// Close
  internal static var close: String { return L10n.tr("Localizable", "close") }
  /// Closed Captions
  internal static var closedCaptions: String { return L10n.tr("Localizable", "closedCaptions") }
  /// Compact
  internal static var compact: String { return L10n.tr("Localizable", "compact") }
  /// Confirm Close
  internal static var confirmClose: String { return L10n.tr("Localizable", "confirmClose") }
  /// Connect
  internal static var connect: String { return L10n.tr("Localizable", "connect") }
  /// Connect Manually
  internal static var connectManually: String { return L10n.tr("Localizable", "connectManually") }
  /// Connect to Jellyfin
  internal static var connectToJellyfin: String { return L10n.tr("Localizable", "connectToJellyfin") }
  /// Connect to a Jellyfin server
  internal static var connectToJellyfinServer: String { return L10n.tr("Localizable", "connectToJellyfinServer") }
  /// Connect to a Jellyfin server to get started
  internal static var connectToJellyfinServerStart: String { return L10n.tr("Localizable", "connectToJellyfinServerStart") }
  /// Connect to Server
  internal static var connectToServer: String { return L10n.tr("Localizable", "connectToServer") }
  /// Containers
  internal static var containers: String { return L10n.tr("Localizable", "containers") }
  /// Continue
  internal static var `continue`: String { return L10n.tr("Localizable", "continue") }
  /// Continue Watching
  internal static var continueWatching: String { return L10n.tr("Localizable", "continueWatching") }
  /// Current Position
  internal static var currentPosition: String { return L10n.tr("Localizable", "currentPosition") }
  /// Customize
  internal static var customize: String { return L10n.tr("Localizable", "customize") }
  /// Dark
  internal static var dark: String { return L10n.tr("Localizable", "dark") }
  /// Default Scheme
  internal static var defaultScheme: String { return L10n.tr("Localizable", "defaultScheme") }
  /// DIRECTOR
  internal static var director: String { return L10n.tr("Localizable", "director") }
  /// Discovered Servers
  internal static var discoveredServers: String { return L10n.tr("Localizable", "discoveredServers") }
  /// Display order
  internal static var displayOrder: String { return L10n.tr("Localizable", "displayOrder") }
  /// Edit Jump Lengths
  internal static var editJumpLengths: String { return L10n.tr("Localizable", "editJumpLengths") }
  /// Empty Next Up
  internal static var emptyNextUp: String { return L10n.tr("Localizable", "emptyNextUp") }
  /// Episodes
  internal static var episodes: String { return L10n.tr("Localizable", "episodes") }
  /// Error
  internal static var error: String { return L10n.tr("Localizable", "error") }
  /// Existing Server
  internal static var existingServer: String { return L10n.tr("Localizable", "existingServer") }
  /// Existing User
  internal static var existingUser: String { return L10n.tr("Localizable", "existingUser") }
  /// Experimental
  internal static var experimental: String { return L10n.tr("Localizable", "experimental") }
  /// Favorites
  internal static var favorites: String { return L10n.tr("Localizable", "favorites") }
  /// File
  internal static var file: String { return L10n.tr("Localizable", "file") }
  /// Filter Results
  internal static var filterResults: String { return L10n.tr("Localizable", "filterResults") }
  /// Filters
  internal static var filters: String { return L10n.tr("Localizable", "filters") }
  /// Genres
  internal static var genres: String { return L10n.tr("Localizable", "genres") }
  /// Home
  internal static var home: String { return L10n.tr("Localizable", "home") }
  /// Information
  internal static var information: String { return L10n.tr("Localizable", "information") }
  /// Items
  internal static var items: String { return L10n.tr("Localizable", "items") }
  /// Jump Backward
  internal static var jumpBackward: String { return L10n.tr("Localizable", "jumpBackward") }
  /// Jump Backward Length
  internal static var jumpBackwardLength: String { return L10n.tr("Localizable", "jumpBackwardLength") }
  /// Jump Forward
  internal static var jumpForward: String { return L10n.tr("Localizable", "jumpForward") }
  /// Jump Forward Length
  internal static var jumpForwardLength: String { return L10n.tr("Localizable", "jumpForwardLength") }
  /// Jump Gestures Enabled
  internal static var jumpGesturesEnabled: String { return L10n.tr("Localizable", "jumpGesturesEnabled") }
  /// %s seconds
  internal static func jumpLengthSeconds(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "jumpLengthSeconds", p1)
  }
  /// Larger
  internal static var larger: String { return L10n.tr("Localizable", "larger") }
  /// Largest
  internal static var largest: String { return L10n.tr("Localizable", "largest") }
  /// Latest %@
  internal static func latestWithString(_ p1: Any) -> String {
    return L10n.tr("Localizable", "latestWithString", String(describing: p1))
  }
  /// Library
  internal static var library: String { return L10n.tr("Localizable", "library") }
  /// Light
  internal static var light: String { return L10n.tr("Localizable", "light") }
  /// Loading
  internal static var loading: String { return L10n.tr("Localizable", "loading") }
  /// Local Servers
  internal static var localServers: String { return L10n.tr("Localizable", "localServers") }
  /// Login
  internal static var login: String { return L10n.tr("Localizable", "login") }
  /// Login to %@
  internal static func loginToWithString(_ p1: Any) -> String {
    return L10n.tr("Localizable", "loginToWithString", String(describing: p1))
  }
  /// Media
  internal static var media: String { return L10n.tr("Localizable", "media") }
  /// Missing
  internal static var missing: String { return L10n.tr("Localizable", "missing") }
  /// Missing Items
  internal static var missingItems: String { return L10n.tr("Localizable", "missingItems") }
  /// More Like This
  internal static var moreLikeThis: String { return L10n.tr("Localizable", "moreLikeThis") }
  /// Movies
  internal static var movies: String { return L10n.tr("Localizable", "movies") }
  /// %d users
  internal static func multipleUsers(_ p1: Int) -> String {
    return L10n.tr("Localizable", "multipleUsers", p1)
  }
  /// Name
  internal static var name: String { return L10n.tr("Localizable", "name") }
  /// Networking
  internal static var networking: String { return L10n.tr("Localizable", "networking") }
  /// Network timed out
  internal static var networkTimedOut: String { return L10n.tr("Localizable", "networkTimedOut") }
  /// Next
  internal static var next: String { return L10n.tr("Localizable", "next") }
  /// Next Item
  internal static var nextItem: String { return L10n.tr("Localizable", "nextItem") }
  /// Next Up
  internal static var nextUp: String { return L10n.tr("Localizable", "nextUp") }
  /// No Cast devices found..
  internal static var noCastdevicesfound: String { return L10n.tr("Localizable", "noCastdevicesfound") }
  /// No Codec
  internal static var noCodec: String { return L10n.tr("Localizable", "noCodec") }
  /// No episodes available
  internal static var noEpisodesAvailable: String { return L10n.tr("Localizable", "noEpisodesAvailable") }
  /// No local servers found
  internal static var noLocalServersFound: String { return L10n.tr("Localizable", "noLocalServersFound") }
  /// None
  internal static var `none`: String { return L10n.tr("Localizable", "none") }
  /// No overview available
  internal static var noOverviewAvailable: String { return L10n.tr("Localizable", "noOverviewAvailable") }
  /// No public users
  internal static var noPublicUsers: String { return L10n.tr("Localizable", "noPublicUsers") }
  /// No results.
  internal static var noResults: String { return L10n.tr("Localizable", "noResults") }
  /// Normal
  internal static var normal: String { return L10n.tr("Localizable", "normal") }
  /// N/A
  internal static var notAvailableSlash: String { return L10n.tr("Localizable", "notAvailableSlash") }
  /// Type: %@ not implemented yet :(
  internal static func notImplementedYetWithType(_ p1: Any) -> String {
    return L10n.tr("Localizable", "notImplementedYetWithType", String(describing: p1))
  }
  /// No title
  internal static var noTitle: String { return L10n.tr("Localizable", "noTitle") }
  /// Ok
  internal static var ok: String { return L10n.tr("Localizable", "ok") }
  /// 1 user
  internal static var oneUser: String { return L10n.tr("Localizable", "oneUser") }
  /// Operating System
  internal static var operatingSystem: String { return L10n.tr("Localizable", "operatingSystem") }
  /// Other
  internal static var other: String { return L10n.tr("Localizable", "other") }
  /// Other User
  internal static var otherUser: String { return L10n.tr("Localizable", "otherUser") }
  /// Overlay
  internal static var overlay: String { return L10n.tr("Localizable", "overlay") }
  /// Overlay Type
  internal static var overlayType: String { return L10n.tr("Localizable", "overlayType") }
  /// Overview
  internal static var overview: String { return L10n.tr("Localizable", "overview") }
  /// Page %1$@ of %2$@
  internal static func pageOfWithNumbers(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "pageOfWithNumbers", String(describing: p1), String(describing: p2))
  }
  /// Password
  internal static var password: String { return L10n.tr("Localizable", "password") }
  /// Play
  internal static var play: String { return L10n.tr("Localizable", "play") }
  /// Play / Pause
  internal static var playAndPause: String { return L10n.tr("Localizable", "playAndPause") }
  /// Playback settings
  internal static var playbackSettings: String { return L10n.tr("Localizable", "playbackSettings") }
  /// Playback Speed
  internal static var playbackSpeed: String { return L10n.tr("Localizable", "playbackSpeed") }
  /// Player Gestures Lock Gesture Enabled
  internal static var playerGesturesLockGestureEnabled: String { return L10n.tr("Localizable", "playerGesturesLockGestureEnabled") }
  /// Play From Beginning
  internal static var playFromBeginning: String { return L10n.tr("Localizable", "playFromBeginning") }
  /// Play Next
  internal static var playNext: String { return L10n.tr("Localizable", "playNext") }
  /// Play Next Item
  internal static var playNextItem: String { return L10n.tr("Localizable", "playNextItem") }
  /// Play Previous Item
  internal static var playPreviousItem: String { return L10n.tr("Localizable", "playPreviousItem") }
  /// Present
  internal static var present: String { return L10n.tr("Localizable", "present") }
  /// Press Down for Menu
  internal static var pressDownForMenu: String { return L10n.tr("Localizable", "pressDownForMenu") }
  /// Previous Item
  internal static var previousItem: String { return L10n.tr("Localizable", "previousItem") }
  /// Programs
  internal static var programs: String { return L10n.tr("Localizable", "programs") }
  /// Public users
  internal static var publicUsers: String { return L10n.tr("Localizable", "publicUsers") }
  /// Rated
  internal static var rated: String { return L10n.tr("Localizable", "rated") }
  /// Recently Added
  internal static var recentlyAdded: String { return L10n.tr("Localizable", "recentlyAdded") }
  /// Recommended
  internal static var recommended: String { return L10n.tr("Localizable", "recommended") }
  /// Refresh
  internal static var refresh: String { return L10n.tr("Localizable", "refresh") }
  /// Regular
  internal static var regular: String { return L10n.tr("Localizable", "regular") }
  /// Released
  internal static var released: String { return L10n.tr("Localizable", "released") }
  /// Remaining Time
  internal static var remainingTime: String { return L10n.tr("Localizable", "remainingTime") }
  /// Remove
  internal static var remove: String { return L10n.tr("Localizable", "remove") }
  /// Remove All Users
  internal static var removeAllUsers: String { return L10n.tr("Localizable", "removeAllUsers") }
  /// Remove From Resume
  internal static var removeFromResume: String { return L10n.tr("Localizable", "removeFromResume") }
  /// Report an Issue
  internal static var reportIssue: String { return L10n.tr("Localizable", "reportIssue") }
  /// Request a Feature
  internal static var requestFeature: String { return L10n.tr("Localizable", "requestFeature") }
  /// Reset
  internal static var reset: String { return L10n.tr("Localizable", "reset") }
  /// Reset App Settings
  internal static var resetAppSettings: String { return L10n.tr("Localizable", "resetAppSettings") }
  /// Reset User Settings
  internal static var resetUserSettings: String { return L10n.tr("Localizable", "resetUserSettings") }
  /// Resume 5 Second Offset
  internal static var resume5SecondOffset: String { return L10n.tr("Localizable", "resume5SecondOffset") }
  /// Retry
  internal static var retry: String { return L10n.tr("Localizable", "retry") }
  /// Runtime
  internal static var runtime: String { return L10n.tr("Localizable", "runtime") }
  /// Search
  internal static var search: String { return L10n.tr("Localizable", "search") }
  /// Search…
  internal static var searchDots: String { return L10n.tr("Localizable", "searchDots") }
  /// Searching…
  internal static var searchingDots: String { return L10n.tr("Localizable", "searchingDots") }
  /// Season
  internal static var season: String { return L10n.tr("Localizable", "season") }
  /// S%1$@:E%2$@
  internal static func seasonAndEpisode(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "seasonAndEpisode", String(describing: p1), String(describing: p2))
  }
  /// Seasons
  internal static var seasons: String { return L10n.tr("Localizable", "seasons") }
  /// See All
  internal static var seeAll: String { return L10n.tr("Localizable", "seeAll") }
  /// Seek Slide Gesture Enabled
  internal static var seekSlideGestureEnabled: String { return L10n.tr("Localizable", "seekSlideGestureEnabled") }
  /// See More
  internal static var seeMore: String { return L10n.tr("Localizable", "seeMore") }
  /// Select Cast Destination
  internal static var selectCastDestination: String { return L10n.tr("Localizable", "selectCastDestination") }
  /// Series
  internal static var series: String { return L10n.tr("Localizable", "series") }
  /// Server
  internal static var server: String { return L10n.tr("Localizable", "server") }
  /// Server %s is already connected
  internal static func serverAlreadyConnected(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "serverAlreadyConnected", p1)
  }
  /// Server %s already exists. Add new URL?
  internal static func serverAlreadyExistsPrompt(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "serverAlreadyExistsPrompt", p1)
  }
  /// Server Details
  internal static var serverDetails: String { return L10n.tr("Localizable", "serverDetails") }
  /// Server Information
  internal static var serverInformation: String { return L10n.tr("Localizable", "serverInformation") }
  /// Servers
  internal static var servers: String { return L10n.tr("Localizable", "servers") }
  /// Server URL
  internal static var serverURL: String { return L10n.tr("Localizable", "serverURL") }
  /// Settings
  internal static var settings: String { return L10n.tr("Localizable", "settings") }
  /// Show Cast & Crew
  internal static var showCastAndCrew: String { return L10n.tr("Localizable", "showCastAndCrew") }
  /// Flatten Library Items
  internal static var showFlattenView: String { return L10n.tr("Localizable", "showFlattenView") }
  /// Show Missing Episodes
  internal static var showMissingEpisodes: String { return L10n.tr("Localizable", "showMissingEpisodes") }
  /// Show Missing Seasons
  internal static var showMissingSeasons: String { return L10n.tr("Localizable", "showMissingSeasons") }
  /// Show Poster Labels
  internal static var showPosterLabels: String { return L10n.tr("Localizable", "showPosterLabels") }
  /// Signed in as %@
  internal static func signedInAsWithString(_ p1: Any) -> String {
    return L10n.tr("Localizable", "signedInAsWithString", String(describing: p1))
  }
  /// Sign In
  internal static var signIn: String { return L10n.tr("Localizable", "signIn") }
  /// Sign in to get started
  internal static var signInGetStarted: String { return L10n.tr("Localizable", "signInGetStarted") }
  /// Sign In to %s
  internal static func signInToServer(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "signInToServer", p1)
  }
  /// Smaller
  internal static var smaller: String { return L10n.tr("Localizable", "smaller") }
  /// Smallest
  internal static var smallest: String { return L10n.tr("Localizable", "smallest") }
  /// Sort by
  internal static var sortBy: String { return L10n.tr("Localizable", "sortBy") }
  /// Source Code
  internal static var sourceCode: String { return L10n.tr("Localizable", "sourceCode") }
  /// STUDIO
  internal static var studio: String { return L10n.tr("Localizable", "studio") }
  /// Studios
  internal static var studios: String { return L10n.tr("Localizable", "studios") }
  /// Subtitles
  internal static var subtitles: String { return L10n.tr("Localizable", "subtitles") }
  /// Subtitle Size
  internal static var subtitleSize: String { return L10n.tr("Localizable", "subtitleSize") }
  /// Suggestions
  internal static var suggestions: String { return L10n.tr("Localizable", "suggestions") }
  /// Switch User
  internal static var switchUser: String { return L10n.tr("Localizable", "switchUser") }
  /// System
  internal static var system: String { return L10n.tr("Localizable", "system") }
  /// System Control Gestures Enabled
  internal static var systemControlGesturesEnabled: String { return L10n.tr("Localizable", "systemControlGesturesEnabled") }
  /// Tags
  internal static var tags: String { return L10n.tr("Localizable", "tags") }
  /// Too Many Redirects
  internal static var tooManyRedirects: String { return L10n.tr("Localizable", "tooManyRedirects") }
  /// Try again
  internal static var tryAgain: String { return L10n.tr("Localizable", "tryAgain") }
  /// TV Shows
  internal static var tvShows: String { return L10n.tr("Localizable", "tvShows") }
  /// Unable to connect to server
  internal static var unableToConnectServer: String { return L10n.tr("Localizable", "unableToConnectServer") }
  /// Unable to find host
  internal static var unableToFindHost: String { return L10n.tr("Localizable", "unableToFindHost") }
  /// Unaired
  internal static var unaired: String { return L10n.tr("Localizable", "unaired") }
  /// Unauthorized
  internal static var unauthorized: String { return L10n.tr("Localizable", "unauthorized") }
  /// Unauthorized user
  internal static var unauthorizedUser: String { return L10n.tr("Localizable", "unauthorizedUser") }
  /// Unknown
  internal static var unknown: String { return L10n.tr("Localizable", "unknown") }
  /// Unknown Error
  internal static var unknownError: String { return L10n.tr("Localizable", "unknownError") }
  /// URL
  internal static var url: String { return L10n.tr("Localizable", "url") }
  /// User
  internal static var user: String { return L10n.tr("Localizable", "user") }
  /// User %s is already signed in
  internal static func userAlreadySignedIn(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "userAlreadySignedIn", p1)
  }
  /// Username
  internal static var username: String { return L10n.tr("Localizable", "username") }
  /// Version
  internal static var version: String { return L10n.tr("Localizable", "version") }
  /// Video Player
  internal static var videoPlayer: String { return L10n.tr("Localizable", "videoPlayer") }
  /// Who's watching?
  internal static var whosWatching: String { return L10n.tr("Localizable", "WhosWatching") }
  /// WIP
  internal static var wip: String { return L10n.tr("Localizable", "wip") }
  /// Your Favorites
  internal static var yourFavorites: String { return L10n.tr("Localizable", "yourFavorites") }
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
