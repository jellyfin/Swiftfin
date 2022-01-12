// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// About
  internal static let about = L10n.tr("Localizable", "about")
  /// Accessibility
  internal static let accessibility = L10n.tr("Localizable", "accessibility")
  /// Add URL
  internal static let addURL = L10n.tr("Localizable", "addURL")
  /// Airs %s
  internal static func airWithDate(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "airWithDate", p1)
  }
  /// All Genres
  internal static let allGenres = L10n.tr("Localizable", "allGenres")
  /// All Media
  internal static let allMedia = L10n.tr("Localizable", "allMedia")
  /// Appearance
  internal static let appearance = L10n.tr("Localizable", "appearance")
  /// Apply
  internal static let apply = L10n.tr("Localizable", "apply")
  /// Audio
  internal static let audio = L10n.tr("Localizable", "audio")
  /// Audio & Captions
  internal static let audioAndCaptions = L10n.tr("Localizable", "audioAndCaptions")
  /// Audio Track
  internal static let audioTrack = L10n.tr("Localizable", "audioTrack")
  /// Auto Play
  internal static let autoPlay = L10n.tr("Localizable", "autoPlay")
  /// Back
  internal static let back = L10n.tr("Localizable", "back")
  /// Cancel
  internal static let cancel = L10n.tr("Localizable", "cancel")
  /// Cannot connect to host
  internal static let cannotConnectToHost = L10n.tr("Localizable", "cannotConnectToHost")
  /// CAST
  internal static let cast = L10n.tr("Localizable", "cast")
  /// Cast & Crew
  internal static let castAndCrew = L10n.tr("Localizable", "castAndCrew")
  /// Change Server
  internal static let changeServer = L10n.tr("Localizable", "changeServer")
  /// Channels
  internal static let channels = L10n.tr("Localizable", "channels")
  /// Cinematic Views
  internal static let cinematicViews = L10n.tr("Localizable", "cinematicViews")
  /// Closed Captions
  internal static let closedCaptions = L10n.tr("Localizable", "closedCaptions")
  /// Compact
  internal static let compact = L10n.tr("Localizable", "compact")
  /// Confirm Close
  internal static let confirmClose = L10n.tr("Localizable", "confirmClose")
  /// Connect
  internal static let connect = L10n.tr("Localizable", "connect")
  /// Connect Manually
  internal static let connectManually = L10n.tr("Localizable", "connectManually")
  /// Connect to Jellyfin
  internal static let connectToJellyfin = L10n.tr("Localizable", "connectToJellyfin")
  /// Connect to a Jellyfin server
  internal static let connectToJellyfinServer = L10n.tr("Localizable", "connectToJellyfinServer")
  /// Connect to a Jellyfin server to get started
  internal static let connectToJellyfinServerStart = L10n.tr("Localizable", "connectToJellyfinServerStart")
  /// Connect to Server
  internal static let connectToServer = L10n.tr("Localizable", "connectToServer")
  /// Containers
  internal static let containers = L10n.tr("Localizable", "containers")
  /// Continue
  internal static let `continue` = L10n.tr("Localizable", "continue")
  /// Continue Watching
  internal static let continueWatching = L10n.tr("Localizable", "continueWatching")
  /// Dark
  internal static let dark = L10n.tr("Localizable", "dark")
  /// Default Scheme
  internal static let defaultScheme = L10n.tr("Localizable", "defaultScheme")
  /// DIRECTOR
  internal static let director = L10n.tr("Localizable", "director")
  /// Discovered Servers
  internal static let discoveredServers = L10n.tr("Localizable", "discoveredServers")
  /// Display order
  internal static let displayOrder = L10n.tr("Localizable", "displayOrder")
  /// Edit Jump Lengths
  internal static let editJumpLengths = L10n.tr("Localizable", "editJumpLengths")
  /// Empty Next Up
  internal static let emptyNextUp = L10n.tr("Localizable", "emptyNextUp")
  /// Episodes
  internal static let episodes = L10n.tr("Localizable", "episodes")
  /// Error
  internal static let error = L10n.tr("Localizable", "error")
  /// Existing Server
  internal static let existingServer = L10n.tr("Localizable", "existingServer")
  /// Existing User
  internal static let existingUser = L10n.tr("Localizable", "existingUser")
  /// Experimental
  internal static let experimental = L10n.tr("Localizable", "experimental")
  /// Favorites
  internal static let favorites = L10n.tr("Localizable", "favorites")
  /// Filter Results
  internal static let filterResults = L10n.tr("Localizable", "filterResults")
  /// Filters
  internal static let filters = L10n.tr("Localizable", "filters")
  /// Genres
  internal static let genres = L10n.tr("Localizable", "genres")
  /// Home
  internal static let home = L10n.tr("Localizable", "home")
  /// Information
  internal static let information = L10n.tr("Localizable", "information")
  /// Items
  internal static let items = L10n.tr("Localizable", "items")
  /// Jump Backward Length
  internal static let jumpBackwardLength = L10n.tr("Localizable", "jumpBackwardLength")
  /// Jump Forward Length
  internal static let jumpForwardLength = L10n.tr("Localizable", "jumpForwardLength")
  /// Jump Gestures Enabled
  internal static let jumpGesturesEnabled = L10n.tr("Localizable", "jumpGesturesEnabled")
  /// %s seconds
  internal static func jumpLengthSeconds(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "jumpLengthSeconds", p1)
  }
  /// Larger
  internal static let larger = L10n.tr("Localizable", "larger")
  /// Largest
  internal static let largest = L10n.tr("Localizable", "largest")
  /// Latest %@
  internal static func latestWithString(_ p1: Any) -> String {
    return L10n.tr("Localizable", "latestWithString", String(describing: p1))
  }
  /// Library
  internal static let library = L10n.tr("Localizable", "library")
  /// Light
  internal static let light = L10n.tr("Localizable", "light")
  /// Loading
  internal static let loading = L10n.tr("Localizable", "loading")
  /// Local Servers
  internal static let localServers = L10n.tr("Localizable", "localServers")
  /// Login
  internal static let login = L10n.tr("Localizable", "login")
  /// Login to %@
  internal static func loginToWithString(_ p1: Any) -> String {
    return L10n.tr("Localizable", "loginToWithString", String(describing: p1))
  }
  /// Media
  internal static let media = L10n.tr("Localizable", "media")
  /// Missing
  internal static let missing = L10n.tr("Localizable", "missing")
  /// Missing Items
  internal static let missingItems = L10n.tr("Localizable", "missingItems")
  /// More Like This
  internal static let moreLikeThis = L10n.tr("Localizable", "moreLikeThis")
  /// Movies
  internal static let movies = L10n.tr("Localizable", "movies")
  /// %d users
  internal static func multipleUsers(_ p1: Int) -> String {
    return L10n.tr("Localizable", "multipleUsers", p1)
  }
  /// Name
  internal static let name = L10n.tr("Localizable", "name")
  /// Networking
  internal static let networking = L10n.tr("Localizable", "networking")
  /// Network timed out
  internal static let networkTimedOut = L10n.tr("Localizable", "networkTimedOut")
  /// Next
  internal static let next = L10n.tr("Localizable", "next")
  /// Next Up
  internal static let nextUp = L10n.tr("Localizable", "nextUp")
  /// No Cast devices found..
  internal static let noCastdevicesfound = L10n.tr("Localizable", "noCastdevicesfound")
  /// No Codec
  internal static let noCodec = L10n.tr("Localizable", "noCodec")
  /// No episodes available
  internal static let noEpisodesAvailable = L10n.tr("Localizable", "noEpisodesAvailable")
  /// No local servers found
  internal static let noLocalServersFound = L10n.tr("Localizable", "noLocalServersFound")
  /// None
  internal static let `none` = L10n.tr("Localizable", "none")
  /// No overview available
  internal static let noOverviewAvailable = L10n.tr("Localizable", "noOverviewAvailable")
  /// No results.
  internal static let noResults = L10n.tr("Localizable", "noResults")
  /// Normal
  internal static let normal = L10n.tr("Localizable", "normal")
  /// N/A
  internal static let notAvailableSlash = L10n.tr("Localizable", "notAvailableSlash")
  /// Type: %@ not implemented yet :(
  internal static func notImplementedYetWithType(_ p1: Any) -> String {
    return L10n.tr("Localizable", "notImplementedYetWithType", String(describing: p1))
  }
  /// No title
  internal static let noTitle = L10n.tr("Localizable", "noTitle")
  /// Ok
  internal static let ok = L10n.tr("Localizable", "ok")
  /// 1 user
  internal static let oneUser = L10n.tr("Localizable", "oneUser")
  /// Operating System
  internal static let operatingSystem = L10n.tr("Localizable", "operatingSystem")
  /// Other
  internal static let other = L10n.tr("Localizable", "other")
  /// Other User
  internal static let otherUser = L10n.tr("Localizable", "otherUser")
  /// Overlay
  internal static let overlay = L10n.tr("Localizable", "overlay")
  /// Overlay Type
  internal static let overlayType = L10n.tr("Localizable", "overlayType")
  /// Overview
  internal static let overview = L10n.tr("Localizable", "overview")
  /// Page %1$@ of %2$@
  internal static func pageOfWithNumbers(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "pageOfWithNumbers", String(describing: p1), String(describing: p2))
  }
  /// Password
  internal static let password = L10n.tr("Localizable", "password")
  /// Play
  internal static let play = L10n.tr("Localizable", "play")
  /// Playback settings
  internal static let playbackSettings = L10n.tr("Localizable", "playbackSettings")
  /// Playback Speed
  internal static let playbackSpeed = L10n.tr("Localizable", "playbackSpeed")
  /// Play Next
  internal static let playNext = L10n.tr("Localizable", "playNext")
  /// Play Next Item
  internal static let playNextItem = L10n.tr("Localizable", "playNextItem")
  /// Play Previous Item
  internal static let playPreviousItem = L10n.tr("Localizable", "playPreviousItem")
  /// Present
  internal static let present = L10n.tr("Localizable", "present")
  /// Press Down for Menu
  internal static let pressDownForMenu = L10n.tr("Localizable", "pressDownForMenu")
  /// Programs
  internal static let programs = L10n.tr("Localizable", "programs")
  /// Rated
  internal static let rated = L10n.tr("Localizable", "rated")
  /// Recently Added
  internal static let recentlyAdded = L10n.tr("Localizable", "recentlyAdded")
  /// Recommended
  internal static let recommended = L10n.tr("Localizable", "recommended")
  /// Refresh
  internal static let refresh = L10n.tr("Localizable", "refresh")
  /// Regular
  internal static let regular = L10n.tr("Localizable", "regular")
  /// Released
  internal static let released = L10n.tr("Localizable", "released")
  /// Remove
  internal static let remove = L10n.tr("Localizable", "remove")
  /// Remove All Users
  internal static let removeAllUsers = L10n.tr("Localizable", "removeAllUsers")
  /// Reset
  internal static let reset = L10n.tr("Localizable", "reset")
  /// Reset App Settings
  internal static let resetAppSettings = L10n.tr("Localizable", "resetAppSettings")
  /// Reset User Settings
  internal static let resetUserSettings = L10n.tr("Localizable", "resetUserSettings")
  /// Resume 5 Second Offset
  internal static let resume5SecondOffset = L10n.tr("Localizable", "resume5SecondOffset")
  /// Retry
  internal static let retry = L10n.tr("Localizable", "retry")
  /// Runtime
  internal static let runtime = L10n.tr("Localizable", "runtime")
  /// Search
  internal static let search = L10n.tr("Localizable", "search")
  /// Search…
  internal static let searchDots = L10n.tr("Localizable", "searchDots")
  /// Searching…
  internal static let searchingDots = L10n.tr("Localizable", "searchingDots")
  /// Season
  internal static let season = L10n.tr("Localizable", "season")
  /// S%1$@:E%2$@
  internal static func seasonAndEpisode(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "seasonAndEpisode", String(describing: p1), String(describing: p2))
  }
  /// Seasons
  internal static let seasons = L10n.tr("Localizable", "seasons")
  /// See All
  internal static let seeAll = L10n.tr("Localizable", "seeAll")
  /// See More
  internal static let seeMore = L10n.tr("Localizable", "seeMore")
  /// Select Cast Destination
  internal static let selectCastDestination = L10n.tr("Localizable", "selectCastDestination")
  /// Series
  internal static let series = L10n.tr("Localizable", "series")
  /// Server
  internal static let server = L10n.tr("Localizable", "server")
  /// Server %s is already connected
  internal static func serverAlreadyConnected(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "serverAlreadyConnected", p1)
  }
  /// Server %s already exists. Add new URL?
  internal static func serverAlreadyExistsPrompt(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "serverAlreadyExistsPrompt", p1)
  }
  /// Server Details
  internal static let serverDetails = L10n.tr("Localizable", "serverDetails")
  /// Server Information
  internal static let serverInformation = L10n.tr("Localizable", "serverInformation")
  /// Servers
  internal static let servers = L10n.tr("Localizable", "servers")
  /// Server URL
  internal static let serverURL = L10n.tr("Localizable", "serverURL")
  /// Settings
  internal static let settings = L10n.tr("Localizable", "settings")
  /// Show Cast & Crew
  internal static let showCastAndCrew = L10n.tr("Localizable", "showCastAndCrew")
  /// Show Missing Episodes
  internal static let showMissingEpisodes = L10n.tr("Localizable", "showMissingEpisodes")
  /// Show Missing Seasons
  internal static let showMissingSeasons = L10n.tr("Localizable", "showMissingSeasons")
  /// Show Poster Labels
  internal static let showPosterLabels = L10n.tr("Localizable", "showPosterLabels")
  /// Signed in as %@
  internal static func signedInAsWithString(_ p1: Any) -> String {
    return L10n.tr("Localizable", "signedInAsWithString", String(describing: p1))
  }
  /// Sign In
  internal static let signIn = L10n.tr("Localizable", "signIn")
  /// Sign in to get started
  internal static let signInGetStarted = L10n.tr("Localizable", "signInGetStarted")
  /// Sign In to %s
  internal static func signInToServer(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "signInToServer", p1)
  }
  /// Smaller
  internal static let smaller = L10n.tr("Localizable", "smaller")
  /// Smallest
  internal static let smallest = L10n.tr("Localizable", "smallest")
  /// Sort by
  internal static let sortBy = L10n.tr("Localizable", "sortBy")
  /// STUDIO
  internal static let studio = L10n.tr("Localizable", "studio")
  /// Studios
  internal static let studios = L10n.tr("Localizable", "studios")
  /// Subtitles
  internal static let subtitles = L10n.tr("Localizable", "subtitles")
  /// Subtitle Size
  internal static let subtitleSize = L10n.tr("Localizable", "subtitleSize")
  /// Suggestions
  internal static let suggestions = L10n.tr("Localizable", "suggestions")
  /// Switch User
  internal static let switchUser = L10n.tr("Localizable", "switchUser")
  /// System
  internal static let system = L10n.tr("Localizable", "system")
  /// Tags
  internal static let tags = L10n.tr("Localizable", "tags")
  /// Try again
  internal static let tryAgain = L10n.tr("Localizable", "tryAgain")
  /// TV Shows
  internal static let tvShows = L10n.tr("Localizable", "tvShows")
  /// Unable to connect to server
  internal static let unableToConnectServer = L10n.tr("Localizable", "unableToConnectServer")
  /// Unaired
  internal static let unaired = L10n.tr("Localizable", "unaired")
  /// Unauthorized
  internal static let unauthorized = L10n.tr("Localizable", "unauthorized")
  /// Unauthorized user
  internal static let unauthorizedUser = L10n.tr("Localizable", "unauthorizedUser")
  /// Unknown
  internal static let unknown = L10n.tr("Localizable", "unknown")
  /// Unknown Error
  internal static let unknownError = L10n.tr("Localizable", "unknownError")
  /// URL
  internal static let url = L10n.tr("Localizable", "url")
  /// User
  internal static let user = L10n.tr("Localizable", "user")
  /// User %s is already signed in
  internal static func userAlreadySignedIn(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "userAlreadySignedIn", p1)
  }
  /// Username
  internal static let username = L10n.tr("Localizable", "username")
  /// Version
  internal static let version = L10n.tr("Localizable", "version")
  /// Video Player
  internal static let videoPlayer = L10n.tr("Localizable", "videoPlayer")
  /// Who's watching?
  internal static let whosWatching = L10n.tr("Localizable", "WhosWatching")
  /// WIP
  internal static let wip = L10n.tr("Localizable", "wip")
  /// Your Favorites
  internal static let yourFavorites = L10n.tr("Localizable", "yourFavorites")
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
