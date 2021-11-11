// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Accessibility
  internal static let accessibility = L10n.tr("Localizable", "accessibility")
  /// All Genres
  internal static let allGenres = L10n.tr("Localizable", "allGenres")
  /// All Media
  internal static let allMedia = L10n.tr("Localizable", "allMedia")
  /// Appearance
  internal static let appearance = L10n.tr("Localizable", "appearance")
  /// Apply
  internal static let apply = L10n.tr("Localizable", "apply")
  /// Audio & Captions
  internal static let audioAndCaptions = L10n.tr("Localizable", "audioAndCaptions")
  /// Audio Track
  internal static let audioTrack = L10n.tr("Localizable", "audioTrack")
  /// Back
  internal static let back = L10n.tr("Localizable", "back")
  /// CAST
  internal static let cast = L10n.tr("Localizable", "cast")
  /// Change Server
  internal static let changeServer = L10n.tr("Localizable", "changeServer")
  /// Closed Captions
  internal static let closedCaptions = L10n.tr("Localizable", "closedCaptions")
  /// Connect
  internal static let connect = L10n.tr("Localizable", "connect")
  /// Connect Manually
  internal static let connectManually = L10n.tr("Localizable", "connectManually")
  /// Connect to Jellyfin
  internal static let connectToJellyfin = L10n.tr("Localizable", "connectToJellyfin")
  /// Connect to Server
  internal static let connectToServer = L10n.tr("Localizable", "connectToServer")
  /// Continue Watching
  internal static let continueWatching = L10n.tr("Localizable", "continueWatching")
  /// Dark
  internal static let dark = L10n.tr("Localizable", "dark")
  /// DIRECTOR
  internal static let director = L10n.tr("Localizable", "director")
  /// Discovered Servers
  internal static let discoveredServers = L10n.tr("Localizable", "discoveredServers")
  /// Display order
  internal static let displayOrder = L10n.tr("Localizable", "displayOrder")
  /// Empty Next Up
  internal static let emptyNextUp = L10n.tr("Localizable", "emptyNextUp")
  /// Episodes
  internal static let episodes = L10n.tr("Localizable", "episodes")
  /// Error
  internal static let error = L10n.tr("Localizable", "error")
  /// Filter Results
  internal static let filterResults = L10n.tr("Localizable", "filterResults")
  /// Filters
  internal static let filters = L10n.tr("Localizable", "filters")
  /// Genres
  internal static let genres = L10n.tr("Localizable", "genres")
  /// Home
  internal static let home = L10n.tr("Localizable", "home")
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
  /// More Like This
  internal static let moreLikeThis = L10n.tr("Localizable", "moreLikeThis")
  /// Next Up
  internal static let nextUp = L10n.tr("Localizable", "nextUp")
  /// No Cast devices found..
  internal static let noCastdevicesfound = L10n.tr("Localizable", "noCastdevicesfound")
  /// No results.
  internal static let noResults = L10n.tr("Localizable", "noResults")
  /// Type: %@ not implemented yet :(
  internal static func notImplementedYetWithType(_ p1: Any) -> String {
    return L10n.tr("Localizable", "notImplementedYetWithType", String(describing: p1))
  }
  /// Ok
  internal static let ok = L10n.tr("Localizable", "ok")
  /// Other User
  internal static let otherUser = L10n.tr("Localizable", "otherUser")
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
  /// Reset
  internal static let reset = L10n.tr("Localizable", "reset")
  /// Search...
  internal static let search = L10n.tr("Localizable", "search")
  /// S%1$@:E%2$@
  internal static func seasonAndEpisode(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "seasonAndEpisode", String(describing: p1), String(describing: p2))
  }
  /// Seasons
  internal static let seasons = L10n.tr("Localizable", "seasons")
  /// See All
  internal static let seeAll = L10n.tr("Localizable", "seeAll")
  /// Select Cast Destination
  internal static let selectCastDestination = L10n.tr("Localizable", "selectCastDestination")
  /// Server Information
  internal static let serverInformation = L10n.tr("Localizable", "serverInformation")
  /// Server URL
  internal static let serverURL = L10n.tr("Localizable", "serverURL")
  /// Signed in as %@
  internal static func signedInAsWithString(_ p1: Any) -> String {
    return L10n.tr("Localizable", "signedInAsWithString", String(describing: p1))
  }
  /// Sort by
  internal static let sortBy = L10n.tr("Localizable", "sortBy")
  /// STUDIO
  internal static let studio = L10n.tr("Localizable", "studio")
  /// Studios
  internal static let studios = L10n.tr("Localizable", "studios")
  /// Suggestions
  internal static let suggestions = L10n.tr("Localizable", "suggestions")
  /// Switch user
  internal static let switchUser = L10n.tr("Localizable", "switchUser")
  /// System
  internal static let system = L10n.tr("Localizable", "system")
  /// Tags
  internal static let tags = L10n.tr("Localizable", "tags")
  /// Try again
  internal static let tryAgain = L10n.tr("Localizable", "tryAgain")
  /// Username
  internal static let username = L10n.tr("Localizable", "username")
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
