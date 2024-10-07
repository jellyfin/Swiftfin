// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// About
  internal static let about = L10n.tr("Localizable", "about", fallback: "About")
  /// Accent Color
  internal static let accentColor = L10n.tr("Localizable", "accentColor", fallback: "Accent Color")
  /// Some views may need an app restart to update.
  internal static let accentColorDescription = L10n.tr("Localizable", "accentColorDescription", fallback: "Some views may need an app restart to update.")
  /// Accessibility
  internal static let accessibility = L10n.tr("Localizable", "accessibility", fallback: "Accessibility")
  /// Active Devices
  internal static let activeDevices = L10n.tr("Localizable", "activeDevices", fallback: "Active Devices")
  /// Add Server
  internal static let addServer = L10n.tr("Localizable", "addServer", fallback: "Add Server")
  /// Add URL
  internal static let addURL = L10n.tr("Localizable", "addURL", fallback: "Add URL")
  /// Administration
  internal static let administration = L10n.tr("Localizable", "administration", fallback: "Administration")
  /// Advanced
  internal static let advanced = L10n.tr("Localizable", "advanced", fallback: "Advanced")
  /// Airs %s
  internal static func airWithDate(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "airWithDate", p1, fallback: "Airs %s")
  }
  /// All Genres
  internal static let allGenres = L10n.tr("Localizable", "allGenres", fallback: "All Genres")
  /// All Media
  internal static let allMedia = L10n.tr("Localizable", "allMedia", fallback: "All Media")
  /// All Servers
  internal static let allServers = L10n.tr("Localizable", "allServers", fallback: "All Servers")
  /// Anamorphic video is not supported
  internal static let anamorphicVideoNotSupported = L10n.tr("Localizable", "anamorphicVideoNotSupported", fallback: "Anamorphic video is not supported")
  /// Appearance
  internal static let appearance = L10n.tr("Localizable", "appearance", fallback: "Appearance")
  /// App Icon
  internal static let appIcon = L10n.tr("Localizable", "appIcon", fallback: "App Icon")
  /// Apply
  internal static let apply = L10n.tr("Localizable", "apply", fallback: "Apply")
  /// Aspect Fill
  internal static let aspectFill = L10n.tr("Localizable", "aspectFill", fallback: "Aspect Fill")
  /// Audio
  internal static let audio = L10n.tr("Localizable", "audio", fallback: "Audio")
  /// Audio & Captions
  internal static let audioAndCaptions = L10n.tr("Localizable", "audioAndCaptions", fallback: "Audio & Captions")
  /// The audio bit depth is not supported
  internal static let audioBitDepthNotSupported = L10n.tr("Localizable", "audioBitDepthNotSupported", fallback: "The audio bit depth is not supported")
  /// The audio bitrate is not supported
  internal static let audioBitrateNotSupported = L10n.tr("Localizable", "audioBitrateNotSupported", fallback: "The audio bitrate is not supported")
  /// The number of audio channels is not supported
  internal static let audioChannelsNotSupported = L10n.tr("Localizable", "audioChannelsNotSupported", fallback: "The number of audio channels is not supported")
  /// The audio codec is not supported
  internal static let audioCodecNotSupported = L10n.tr("Localizable", "audioCodecNotSupported", fallback: "The audio codec is not supported")
  /// The audio track is external and requires transcoding
  internal static let audioIsExternal = L10n.tr("Localizable", "audioIsExternal", fallback: "The audio track is external and requires transcoding")
  /// Audio Offset
  internal static let audioOffset = L10n.tr("Localizable", "audioOffset", fallback: "Audio Offset")
  /// The audio profile is not supported
  internal static let audioProfileNotSupported = L10n.tr("Localizable", "audioProfileNotSupported", fallback: "The audio profile is not supported")
  /// The audio sample rate is not supported
  internal static let audioSampleRateNotSupported = L10n.tr("Localizable", "audioSampleRateNotSupported", fallback: "The audio sample rate is not supported")
  /// Audio Track
  internal static let audioTrack = L10n.tr("Localizable", "audioTrack", fallback: "Audio Track")
  /// Authorize
  internal static let authorize = L10n.tr("Localizable", "authorize", fallback: "Authorize")
  /// Auto
  internal static let auto = L10n.tr("Localizable", "auto", fallback: "Auto")
  /// Auto Play
  internal static let autoPlay = L10n.tr("Localizable", "autoPlay", fallback: "Auto Play")
  /// Back
  internal static let back = L10n.tr("Localizable", "back", fallback: "Back")
  /// Bar Buttons
  internal static let barButtons = L10n.tr("Localizable", "barButtons", fallback: "Bar Buttons")
  /// Behavior
  internal static let behavior = L10n.tr("Localizable", "behavior", fallback: "Behavior")
  /// Auto
  internal static let bitrateAuto = L10n.tr("Localizable", "bitrateAuto", fallback: "Auto")
  /// Default Bitrate
  internal static let bitrateDefault = L10n.tr("Localizable", "bitrateDefault", fallback: "Default Bitrate")
  /// Limits the internet bandwidth used during video playback
  internal static let bitrateDefaultDescription = L10n.tr("Localizable", "bitrateDefaultDescription", fallback: "Limits the internet bandwidth used during video playback")
  /// 480p - 1.5 Mbps
  internal static let bitrateKbps1500 = L10n.tr("Localizable", "bitrateKbps1500", fallback: "480p - 1.5 Mbps")
  /// 360p - 420 Kbps
  internal static let bitrateKbps420 = L10n.tr("Localizable", "bitrateKbps420", fallback: "360p - 420 Kbps")
  /// 480p - 720 Kbps
  internal static let bitrateKbps720 = L10n.tr("Localizable", "bitrateKbps720", fallback: "480p - 720 Kbps")
  /// Maximum
  internal static let bitrateMax = L10n.tr("Localizable", "bitrateMax", fallback: "Maximum")
  /// 1080p - 10 Mbps
  internal static let bitrateMbps10 = L10n.tr("Localizable", "bitrateMbps10", fallback: "1080p - 10 Mbps")
  /// 4K - 120 Mbps
  internal static let bitrateMbps120 = L10n.tr("Localizable", "bitrateMbps120", fallback: "4K - 120 Mbps")
  /// 1080p - 15 Mbps
  internal static let bitrateMbps15 = L10n.tr("Localizable", "bitrateMbps15", fallback: "1080p - 15 Mbps")
  /// 1080p - 20 Mbps
  internal static let bitrateMbps20 = L10n.tr("Localizable", "bitrateMbps20", fallback: "1080p - 20 Mbps")
  /// 480p - 3 Mbps
  internal static let bitrateMbps3 = L10n.tr("Localizable", "bitrateMbps3", fallback: "480p - 3 Mbps")
  /// 720p - 4 Mbps
  internal static let bitrateMbps4 = L10n.tr("Localizable", "bitrateMbps4", fallback: "720p - 4 Mbps")
  /// 1080p - 40 Mbps
  internal static let bitrateMbps40 = L10n.tr("Localizable", "bitrateMbps40", fallback: "1080p - 40 Mbps")
  /// 720p - 6 Mbps
  internal static let bitrateMbps6 = L10n.tr("Localizable", "bitrateMbps6", fallback: "720p - 6 Mbps")
  /// 1080p - 60 Mbps
  internal static let bitrateMbps60 = L10n.tr("Localizable", "bitrateMbps60", fallback: "1080p - 60 Mbps")
  /// 720p - 8 Mbps
  internal static let bitrateMbps8 = L10n.tr("Localizable", "bitrateMbps8", fallback: "720p - 8 Mbps")
  /// 4K - 80 Mbps
  internal static let bitrateMbps80 = L10n.tr("Localizable", "bitrateMbps80", fallback: "4K - 80 Mbps")
  /// Bitrate Test
  internal static let bitrateTest = L10n.tr("Localizable", "bitrateTest", fallback: "Bitrate Test")
  /// Determines the length of the 'Auto' bitrate test used to find the available internet bandwidth
  internal static let bitrateTestDescription = L10n.tr("Localizable", "bitrateTestDescription", fallback: "Determines the length of the 'Auto' bitrate test used to find the available internet bandwidth")
  /// Longer tests are more accurate but may result in a delayed playback
  internal static let bitrateTestDisclaimer = L10n.tr("Localizable", "bitrateTestDisclaimer", fallback: "Longer tests are more accurate but may result in a delayed playback")
  /// Blue
  internal static let blue = L10n.tr("Localizable", "blue", fallback: "Blue")
  /// Bugs and Features
  internal static let bugsAndFeatures = L10n.tr("Localizable", "bugsAndFeatures", fallback: "Bugs and Features")
  /// Buttons
  internal static let buttons = L10n.tr("Localizable", "buttons", fallback: "Buttons")
  /// Cancel
  internal static let cancel = L10n.tr("Localizable", "cancel", fallback: "Cancel")
  /// Cancelled
  internal static let canceled = L10n.tr("Localizable", "canceled", fallback: "Cancelled")
  /// Cancelling...
  internal static let cancelling = L10n.tr("Localizable", "cancelling", fallback: "Cancelling...")
  /// Cannot connect to host
  internal static let cannotConnectToHost = L10n.tr("Localizable", "cannotConnectToHost", fallback: "Cannot connect to host")
  /// CAST
  internal static let cast = L10n.tr("Localizable", "cast", fallback: "CAST")
  /// Cast & Crew
  internal static let castAndCrew = L10n.tr("Localizable", "castAndCrew", fallback: "Cast & Crew")
  /// Category
  internal static let category = L10n.tr("Localizable", "category", fallback: "Category")
  /// Change Server
  internal static let changeServer = L10n.tr("Localizable", "changeServer", fallback: "Change Server")
  /// Channels
  internal static let channels = L10n.tr("Localizable", "channels", fallback: "Channels")
  /// Chapters
  internal static let chapters = L10n.tr("Localizable", "chapters", fallback: "Chapters")
  /// Chapter Slider
  internal static let chapterSlider = L10n.tr("Localizable", "chapterSlider", fallback: "Chapter Slider")
  /// Cinematic
  internal static let cinematic = L10n.tr("Localizable", "cinematic", fallback: "Cinematic")
  /// Cinematic Background
  internal static let cinematicBackground = L10n.tr("Localizable", "cinematicBackground", fallback: "Cinematic Background")
  /// Cinematic Views
  internal static let cinematicViews = L10n.tr("Localizable", "cinematicViews", fallback: "Cinematic Views")
  /// Client
  internal static let client = L10n.tr("Localizable", "client", fallback: "Client")
  /// Close
  internal static let close = L10n.tr("Localizable", "close", fallback: "Close")
  /// Closed Captions
  internal static let closedCaptions = L10n.tr("Localizable", "closedCaptions", fallback: "Closed Captions")
  /// Collections
  internal static let collections = L10n.tr("Localizable", "collections", fallback: "Collections")
  /// Color
  internal static let color = L10n.tr("Localizable", "color", fallback: "Color")
  /// Coming soon
  internal static let comingSoon = L10n.tr("Localizable", "comingSoon", fallback: "Coming soon")
  /// Compact
  internal static let compact = L10n.tr("Localizable", "compact", fallback: "Compact")
  /// Compact Logo
  internal static let compactLogo = L10n.tr("Localizable", "compactLogo", fallback: "Compact Logo")
  /// Compact Poster
  internal static let compactPoster = L10n.tr("Localizable", "compactPoster", fallback: "Compact Poster")
  /// Compatibility
  internal static let compatibility = L10n.tr("Localizable", "compatibility", fallback: "Compatibility")
  /// Most Compatible
  internal static let compatible = L10n.tr("Localizable", "compatible", fallback: "Most Compatible")
  /// Confirm
  internal static let confirm = L10n.tr("Localizable", "confirm", fallback: "Confirm")
  /// Confirm Close
  internal static let confirmClose = L10n.tr("Localizable", "confirmClose", fallback: "Confirm Close")
  /// Connect
  internal static let connect = L10n.tr("Localizable", "connect", fallback: "Connect")
  /// Connect Manually
  internal static let connectManually = L10n.tr("Localizable", "connectManually", fallback: "Connect Manually")
  /// Connect to Jellyfin
  internal static let connectToJellyfin = L10n.tr("Localizable", "connectToJellyfin", fallback: "Connect to Jellyfin")
  /// Connect to a Jellyfin server
  internal static let connectToJellyfinServer = L10n.tr("Localizable", "connectToJellyfinServer", fallback: "Connect to a Jellyfin server")
  /// Connect to a Jellyfin server to get started
  internal static let connectToJellyfinServerStart = L10n.tr("Localizable", "connectToJellyfinServerStart", fallback: "Connect to a Jellyfin server to get started")
  /// Connect to Server
  internal static let connectToServer = L10n.tr("Localizable", "connectToServer", fallback: "Connect to Server")
  /// The container bitrate exceeds the allowed limit
  internal static let containerBitrateExceedsLimit = L10n.tr("Localizable", "containerBitrateExceedsLimit", fallback: "The container bitrate exceeds the allowed limit")
  /// The container format is not supported
  internal static let containerNotSupported = L10n.tr("Localizable", "containerNotSupported", fallback: "The container format is not supported")
  /// Containers
  internal static let containers = L10n.tr("Localizable", "containers", fallback: "Containers")
  /// Continue
  internal static let `continue` = L10n.tr("Localizable", "continue", fallback: "Continue")
  /// Continue Watching
  internal static let continueWatching = L10n.tr("Localizable", "continueWatching", fallback: "Continue Watching")
  /// Current
  internal static let current = L10n.tr("Localizable", "current", fallback: "Current")
  /// Current Position
  internal static let currentPosition = L10n.tr("Localizable", "currentPosition", fallback: "Current Position")
  /// Custom
  internal static let custom = L10n.tr("Localizable", "custom", fallback: "Custom")
  /// The custom device profiles will be added to the default Swiftfin device profiles
  internal static let customDeviceProfileAdd = L10n.tr("Localizable", "customDeviceProfileAdd", fallback: "The custom device profiles will be added to the default Swiftfin device profiles")
  /// Dictates back to the Jellyfin Server what this device hardware is capable of playing
  internal static let customDeviceProfileDescription = L10n.tr("Localizable", "customDeviceProfileDescription", fallback: "Dictates back to the Jellyfin Server what this device hardware is capable of playing")
  /// The custom device profiles will replace the default Swiftfin device profiles
  internal static let customDeviceProfileReplace = L10n.tr("Localizable", "customDeviceProfileReplace", fallback: "The custom device profiles will replace the default Swiftfin device profiles")
  /// Customize
  internal static let customize = L10n.tr("Localizable", "customize", fallback: "Customize")
  /// Custom Profile
  internal static let customProfile = L10n.tr("Localizable", "customProfile", fallback: "Custom Profile")
  /// Dark
  internal static let dark = L10n.tr("Localizable", "dark", fallback: "Dark")
  /// Dashboard
  internal static let dashboard = L10n.tr("Localizable", "dashboard", fallback: "Dashboard")
  /// Perform administrative tasks for your Jellyfin server.
  internal static let dashboardDescription = L10n.tr("Localizable", "dashboardDescription", fallback: "Perform administrative tasks for your Jellyfin server.")
  /// Default Scheme
  internal static let defaultScheme = L10n.tr("Localizable", "defaultScheme", fallback: "Default Scheme")
  /// Delete
  internal static let delete = L10n.tr("Localizable", "delete", fallback: "Delete")
  /// Delete Server
  internal static let deleteServer = L10n.tr("Localizable", "deleteServer", fallback: "Delete Server")
  /// Delivery
  internal static let delivery = L10n.tr("Localizable", "delivery", fallback: "Delivery")
  /// Device
  internal static let device = L10n.tr("Localizable", "device", fallback: "Device")
  /// Device Profile
  internal static let deviceProfile = L10n.tr("Localizable", "deviceProfile", fallback: "Device Profile")
  /// Direct Play
  internal static let direct = L10n.tr("Localizable", "direct", fallback: "Direct Play")
  /// DIRECTOR
  internal static let director = L10n.tr("Localizable", "director", fallback: "DIRECTOR")
  /// Direct Play
  internal static let directPlay = L10n.tr("Localizable", "directPlay", fallback: "Direct Play")
  /// An error occurred during direct play
  internal static let directPlayError = L10n.tr("Localizable", "directPlayError", fallback: "An error occurred during direct play")
  /// Direct Stream
  internal static let directStream = L10n.tr("Localizable", "directStream", fallback: "Direct Stream")
  /// Disabled
  internal static let disabled = L10n.tr("Localizable", "disabled", fallback: "Disabled")
  /// Discovered Servers
  internal static let discoveredServers = L10n.tr("Localizable", "discoveredServers", fallback: "Discovered Servers")
  /// Dismiss
  internal static let dismiss = L10n.tr("Localizable", "dismiss", fallback: "Dismiss")
  /// Display order
  internal static let displayOrder = L10n.tr("Localizable", "displayOrder", fallback: "Display order")
  /// Done
  internal static let done = L10n.tr("Localizable", "done", fallback: "Done")
  /// Downloads
  internal static let downloads = L10n.tr("Localizable", "downloads", fallback: "Downloads")
  /// Edit
  internal static let edit = L10n.tr("Localizable", "edit", fallback: "Edit")
  /// Edit Jump Lengths
  internal static let editJumpLengths = L10n.tr("Localizable", "editJumpLengths", fallback: "Edit Jump Lengths")
  /// Edit Server
  internal static let editServer = L10n.tr("Localizable", "editServer", fallback: "Edit Server")
  /// Empty Next Up
  internal static let emptyNextUp = L10n.tr("Localizable", "emptyNextUp", fallback: "Empty Next Up")
  /// Enabled
  internal static let enabled = L10n.tr("Localizable", "enabled", fallback: "Enabled")
  /// Episode Landscape Poster
  internal static let episodeLandscapePoster = L10n.tr("Localizable", "episodeLandscapePoster", fallback: "Episode Landscape Poster")
  /// Episode %1$@
  internal static func episodeNumber(_ p1: Any) -> String {
    return L10n.tr("Localizable", "episodeNumber", String(describing: p1), fallback: "Episode %1$@")
  }
  /// Episodes
  internal static let episodes = L10n.tr("Localizable", "episodes", fallback: "Episodes")
  /// Error
  internal static let error = L10n.tr("Localizable", "error", fallback: "Error")
  /// Existing Server
  internal static let existingServer = L10n.tr("Localizable", "existingServer", fallback: "Existing Server")
  /// Existing User
  internal static let existingUser = L10n.tr("Localizable", "existingUser", fallback: "Existing User")
  /// Experimental
  internal static let experimental = L10n.tr("Localizable", "experimental", fallback: "Experimental")
  /// Favorited
  internal static let favorited = L10n.tr("Localizable", "favorited", fallback: "Favorited")
  /// Favorites
  internal static let favorites = L10n.tr("Localizable", "favorites", fallback: "Favorites")
  /// File
  internal static let file = L10n.tr("Localizable", "file", fallback: "File")
  /// Filter Results
  internal static let filterResults = L10n.tr("Localizable", "filterResults", fallback: "Filter Results")
  /// Filters
  internal static let filters = L10n.tr("Localizable", "filters", fallback: "Filters")
  /// %@fps
  internal static func fpsWithString(_ p1: Any) -> String {
    return L10n.tr("Localizable", "fpsWithString", String(describing: p1), fallback: "%@fps")
  }
  /// Genres
  internal static let genres = L10n.tr("Localizable", "genres", fallback: "Genres")
  /// Gestures
  internal static let gestures = L10n.tr("Localizable", "gestures", fallback: "Gestures")
  /// Green
  internal static let green = L10n.tr("Localizable", "green", fallback: "Green")
  /// Grid
  internal static let grid = L10n.tr("Localizable", "grid", fallback: "Grid")
  /// Haptic Feedback
  internal static let hapticFeedback = L10n.tr("Localizable", "hapticFeedback", fallback: "Haptic Feedback")
  /// Home
  internal static let home = L10n.tr("Localizable", "home", fallback: "Home")
  /// Indicators
  internal static let indicators = L10n.tr("Localizable", "indicators", fallback: "Indicators")
  /// Information
  internal static let information = L10n.tr("Localizable", "information", fallback: "Information")
  /// Interlaced video is not supported
  internal static let interlacedVideoNotSupported = L10n.tr("Localizable", "interlacedVideoNotSupported", fallback: "Interlaced video is not supported")
  /// Inverted Dark
  internal static let invertedDark = L10n.tr("Localizable", "invertedDark", fallback: "Inverted Dark")
  /// Inverted Light
  internal static let invertedLight = L10n.tr("Localizable", "invertedLight", fallback: "Inverted Light")
  /// %1$@ / %2$@
  internal static func itemOverItem(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "itemOverItem", String(describing: p1), String(describing: p2), fallback: "%1$@ / %2$@")
  }
  /// Items
  internal static let items = L10n.tr("Localizable", "items", fallback: "Items")
  /// Jellyfin
  internal static let jellyfin = L10n.tr("Localizable", "jellyfin", fallback: "Jellyfin")
  /// Jump
  internal static let jump = L10n.tr("Localizable", "jump", fallback: "Jump")
  /// Jump Backward
  internal static let jumpBackward = L10n.tr("Localizable", "jumpBackward", fallback: "Jump Backward")
  /// Jump Backward Length
  internal static let jumpBackwardLength = L10n.tr("Localizable", "jumpBackwardLength", fallback: "Jump Backward Length")
  /// Jump Forward
  internal static let jumpForward = L10n.tr("Localizable", "jumpForward", fallback: "Jump Forward")
  /// Jump Forward Length
  internal static let jumpForwardLength = L10n.tr("Localizable", "jumpForwardLength", fallback: "Jump Forward Length")
  /// Jump Gestures Enabled
  internal static let jumpGesturesEnabled = L10n.tr("Localizable", "jumpGesturesEnabled", fallback: "Jump Gestures Enabled")
  /// %s seconds
  internal static func jumpLengthSeconds(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "jumpLengthSeconds", p1, fallback: "%s seconds")
  }
  /// Kids
  internal static let kids = L10n.tr("Localizable", "kids", fallback: "Kids")
  /// Larger
  internal static let larger = L10n.tr("Localizable", "larger", fallback: "Larger")
  /// Largest
  internal static let largest = L10n.tr("Localizable", "largest", fallback: "Largest")
  /// Last run
  internal static let lastRun = L10n.tr("Localizable", "lastRun", fallback: "Last run")
  /// Last ran %@
  internal static func lastRunTime(_ p1: Any) -> String {
    return L10n.tr("Localizable", "lastRunTime", String(describing: p1), fallback: "Last ran %@")
  }
  /// Last Seen
  internal static let lastSeen = L10n.tr("Localizable", "lastSeen", fallback: "Last Seen")
  /// Latest %@
  internal static func latestWithString(_ p1: Any) -> String {
    return L10n.tr("Localizable", "latestWithString", String(describing: p1), fallback: "Latest %@")
  }
  /// Left
  internal static let `left` = L10n.tr("Localizable", "left", fallback: "Left")
  /// Letter Picker
  internal static let letterPicker = L10n.tr("Localizable", "letterPicker", fallback: "Letter Picker")
  /// Library
  internal static let library = L10n.tr("Localizable", "library", fallback: "Library")
  /// Light
  internal static let light = L10n.tr("Localizable", "light", fallback: "Light")
  /// List
  internal static let list = L10n.tr("Localizable", "list", fallback: "List")
  /// Live TV
  internal static let liveTV = L10n.tr("Localizable", "liveTV", fallback: "Live TV")
  /// Loading
  internal static let loading = L10n.tr("Localizable", "loading", fallback: "Loading")
  /// Local Servers
  internal static let localServers = L10n.tr("Localizable", "localServers", fallback: "Local Servers")
  /// Login
  internal static let login = L10n.tr("Localizable", "login", fallback: "Login")
  /// Login to %@
  internal static func loginToWithString(_ p1: Any) -> String {
    return L10n.tr("Localizable", "loginToWithString", String(describing: p1), fallback: "Login to %@")
  }
  /// Logs
  internal static let logs = L10n.tr("Localizable", "logs", fallback: "Logs")
  /// Maximum Bitrate
  internal static let maximumBitrate = L10n.tr("Localizable", "maximumBitrate", fallback: "Maximum Bitrate")
  /// This setting may result in media failing to start playback
  internal static let mayResultInPlaybackFailure = L10n.tr("Localizable", "mayResultInPlaybackFailure", fallback: "This setting may result in media failing to start playback")
  /// Media
  internal static let media = L10n.tr("Localizable", "media", fallback: "Media")
  /// Menu Buttons
  internal static let menuButtons = L10n.tr("Localizable", "menuButtons", fallback: "Menu Buttons")
  /// Method
  internal static let method = L10n.tr("Localizable", "method", fallback: "Method")
  /// Missing
  internal static let missing = L10n.tr("Localizable", "missing", fallback: "Missing")
  /// Missing Items
  internal static let missingItems = L10n.tr("Localizable", "missingItems", fallback: "Missing Items")
  /// More Like This
  internal static let moreLikeThis = L10n.tr("Localizable", "moreLikeThis", fallback: "More Like This")
  /// Movies
  internal static let movies = L10n.tr("Localizable", "movies", fallback: "Movies")
  /// %d users
  internal static func multipleUsers(_ p1: Int) -> String {
    return L10n.tr("Localizable", "multipleUsers", p1, fallback: "%d users")
  }
  /// Name
  internal static let name = L10n.tr("Localizable", "name", fallback: "Name")
  /// Native Player
  internal static let nativePlayer = L10n.tr("Localizable", "nativePlayer", fallback: "Native Player")
  /// Networking
  internal static let networking = L10n.tr("Localizable", "networking", fallback: "Networking")
  /// Network timed out
  internal static let networkTimedOut = L10n.tr("Localizable", "networkTimedOut", fallback: "Network timed out")
  /// Never run
  internal static let neverRun = L10n.tr("Localizable", "neverRun", fallback: "Never run")
  /// News
  internal static let news = L10n.tr("Localizable", "news", fallback: "News")
  /// Next
  internal static let next = L10n.tr("Localizable", "next", fallback: "Next")
  /// Next Item
  internal static let nextItem = L10n.tr("Localizable", "nextItem", fallback: "Next Item")
  /// Next Up
  internal static let nextUp = L10n.tr("Localizable", "nextUp", fallback: "Next Up")
  /// Days in Next Up
  internal static let nextUpDays = L10n.tr("Localizable", "nextUpDays", fallback: "Days in Next Up")
  /// Set the maximum amount of days a show should stay in the 'Next Up' list without watching it.
  internal static let nextUpDaysDescription = L10n.tr("Localizable", "nextUpDaysDescription", fallback: "Set the maximum amount of days a show should stay in the 'Next Up' list without watching it.")
  /// Rewatching in Next Up
  internal static let nextUpRewatch = L10n.tr("Localizable", "nextUpRewatch", fallback: "Rewatching in Next Up")
  /// No Cast devices found..
  internal static let noCastdevicesfound = L10n.tr("Localizable", "noCastdevicesfound", fallback: "No Cast devices found..")
  /// No Codec
  internal static let noCodec = L10n.tr("Localizable", "noCodec", fallback: "No Codec")
  /// No episodes available
  internal static let noEpisodesAvailable = L10n.tr("Localizable", "noEpisodesAvailable", fallback: "No episodes available")
  /// No local servers found
  internal static let noLocalServersFound = L10n.tr("Localizable", "noLocalServersFound", fallback: "No local servers found")
  /// None
  internal static let `none` = L10n.tr("Localizable", "none", fallback: "None")
  /// No overview available
  internal static let noOverviewAvailable = L10n.tr("Localizable", "noOverviewAvailable", fallback: "No overview available")
  /// No public Users
  internal static let noPublicUsers = L10n.tr("Localizable", "noPublicUsers", fallback: "No public Users")
  /// No results.
  internal static let noResults = L10n.tr("Localizable", "noResults", fallback: "No results.")
  /// Normal
  internal static let normal = L10n.tr("Localizable", "normal", fallback: "Normal")
  /// No session
  internal static let noSession = L10n.tr("Localizable", "noSession", fallback: "No session")
  /// N/A
  internal static let notAvailableSlash = L10n.tr("Localizable", "notAvailableSlash", fallback: "N/A")
  /// Type: %@ not implemented yet :(
  internal static func notImplementedYetWithType(_ p1: Any) -> String {
    return L10n.tr("Localizable", "notImplementedYetWithType", String(describing: p1), fallback: "Type: %@ not implemented yet :(")
  }
  /// No title
  internal static let noTitle = L10n.tr("Localizable", "noTitle", fallback: "No title")
  /// Offset
  internal static let offset = L10n.tr("Localizable", "offset", fallback: "Offset")
  /// Ok
  internal static let ok = L10n.tr("Localizable", "ok", fallback: "Ok")
  /// 1 user
  internal static let oneUser = L10n.tr("Localizable", "oneUser", fallback: "1 user")
  /// Online
  internal static let online = L10n.tr("Localizable", "online", fallback: "Online")
  /// On Now
  internal static let onNow = L10n.tr("Localizable", "onNow", fallback: "On Now")
  /// Operating System
  internal static let operatingSystem = L10n.tr("Localizable", "operatingSystem", fallback: "Operating System")
  /// Orange
  internal static let orange = L10n.tr("Localizable", "orange", fallback: "Orange")
  /// Order
  internal static let order = L10n.tr("Localizable", "order", fallback: "Order")
  /// Orientation
  internal static let orientation = L10n.tr("Localizable", "orientation", fallback: "Orientation")
  /// Other
  internal static let other = L10n.tr("Localizable", "other", fallback: "Other")
  /// Other User
  internal static let otherUser = L10n.tr("Localizable", "otherUser", fallback: "Other User")
  /// Overlay
  internal static let overlay = L10n.tr("Localizable", "overlay", fallback: "Overlay")
  /// Overlay Type
  internal static let overlayType = L10n.tr("Localizable", "overlayType", fallback: "Overlay Type")
  /// Overview
  internal static let overview = L10n.tr("Localizable", "overview", fallback: "Overview")
  /// Page %1$@ of %2$@
  internal static func pageOfWithNumbers(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "pageOfWithNumbers", String(describing: p1), String(describing: p2), fallback: "Page %1$@ of %2$@")
  }
  /// Password
  internal static let password = L10n.tr("Localizable", "password", fallback: "Password")
  /// Pause on background
  internal static let pauseOnBackground = L10n.tr("Localizable", "pauseOnBackground", fallback: "Pause on background")
  /// People
  internal static let people = L10n.tr("Localizable", "people", fallback: "People")
  /// Play
  internal static let play = L10n.tr("Localizable", "play", fallback: "Play")
  /// Play / Pause
  internal static let playAndPause = L10n.tr("Localizable", "playAndPause", fallback: "Play / Pause")
  /// Playback
  internal static let playback = L10n.tr("Localizable", "playback", fallback: "Playback")
  /// Playback Buttons
  internal static let playbackButtons = L10n.tr("Localizable", "playbackButtons", fallback: "Playback Buttons")
  /// Playback Quality
  internal static let playbackQuality = L10n.tr("Localizable", "playbackQuality", fallback: "Playback Quality")
  /// Playback settings
  internal static let playbackSettings = L10n.tr("Localizable", "playbackSettings", fallback: "Playback settings")
  /// Playback Speed
  internal static let playbackSpeed = L10n.tr("Localizable", "playbackSpeed", fallback: "Playback Speed")
  /// Played
  internal static let played = L10n.tr("Localizable", "played", fallback: "Played")
  /// Player Gestures Lock Gesture Enabled
  internal static let playerGesturesLockGestureEnabled = L10n.tr("Localizable", "playerGesturesLockGestureEnabled", fallback: "Player Gestures Lock Gesture Enabled")
  /// Play From Beginning
  internal static let playFromBeginning = L10n.tr("Localizable", "playFromBeginning", fallback: "Play From Beginning")
  /// Play Next
  internal static let playNext = L10n.tr("Localizable", "playNext", fallback: "Play Next")
  /// Play Next Item
  internal static let playNextItem = L10n.tr("Localizable", "playNextItem", fallback: "Play Next Item")
  /// Play on active
  internal static let playOnActive = L10n.tr("Localizable", "playOnActive", fallback: "Play on active")
  /// Play Previous Item
  internal static let playPreviousItem = L10n.tr("Localizable", "playPreviousItem", fallback: "Play Previous Item")
  /// Posters
  internal static let posters = L10n.tr("Localizable", "posters", fallback: "Posters")
  /// Present
  internal static let present = L10n.tr("Localizable", "present", fallback: "Present")
  /// Press Down for Menu
  internal static let pressDownForMenu = L10n.tr("Localizable", "pressDownForMenu", fallback: "Press Down for Menu")
  /// Previous Item
  internal static let previousItem = L10n.tr("Localizable", "previousItem", fallback: "Previous Item")
  /// Primary
  internal static let primary = L10n.tr("Localizable", "primary", fallback: "Primary")
  /// Profiles
  internal static let profiles = L10n.tr("Localizable", "profiles", fallback: "Profiles")
  /// Programs
  internal static let programs = L10n.tr("Localizable", "programs", fallback: "Programs")
  /// Progress
  internal static let progress = L10n.tr("Localizable", "progress", fallback: "Progress")
  /// Public Users
  internal static let publicUsers = L10n.tr("Localizable", "publicUsers", fallback: "Public Users")
  /// Quick Connect
  internal static let quickConnect = L10n.tr("Localizable", "quickConnect", fallback: "Quick Connect")
  /// Quick Connect code
  internal static let quickConnectCode = L10n.tr("Localizable", "quickConnectCode", fallback: "Quick Connect code")
  /// Invalid Quick Connect code
  internal static let quickConnectInvalidError = L10n.tr("Localizable", "quickConnectInvalidError", fallback: "Invalid Quick Connect code")
  /// Note: Quick Connect not enabled
  internal static let quickConnectNotEnabled = L10n.tr("Localizable", "quickConnectNotEnabled", fallback: "Note: Quick Connect not enabled")
  /// 1. Open the Jellyfin app on your phone or web browser and sign in with your account
  internal static let quickConnectStep1 = L10n.tr("Localizable", "quickConnectStep1", fallback: "1. Open the Jellyfin app on your phone or web browser and sign in with your account")
  /// 2. Open the user menu and go to the Quick Connect page
  internal static let quickConnectStep2 = L10n.tr("Localizable", "quickConnectStep2", fallback: "2. Open the user menu and go to the Quick Connect page")
  /// 3. Enter the following code:
  internal static let quickConnectStep3 = L10n.tr("Localizable", "quickConnectStep3", fallback: "3. Enter the following code:")
  /// Authorizing Quick Connect successful. Please continue on your other device.
  internal static let quickConnectSuccessMessage = L10n.tr("Localizable", "quickConnectSuccessMessage", fallback: "Authorizing Quick Connect successful. Please continue on your other device.")
  /// Random
  internal static let random = L10n.tr("Localizable", "random", fallback: "Random")
  /// Random Image
  internal static let randomImage = L10n.tr("Localizable", "randomImage", fallback: "Random Image")
  /// Rated
  internal static let rated = L10n.tr("Localizable", "rated", fallback: "Rated")
  /// Ratings
  internal static let ratings = L10n.tr("Localizable", "ratings", fallback: "Ratings")
  /// Recently Added
  internal static let recentlyAdded = L10n.tr("Localizable", "recentlyAdded", fallback: "Recently Added")
  /// Recommended
  internal static let recommended = L10n.tr("Localizable", "recommended", fallback: "Recommended")
  /// Red
  internal static let red = L10n.tr("Localizable", "red", fallback: "Red")
  /// The number of reference frames is not supported
  internal static let refFramesNotSupported = L10n.tr("Localizable", "refFramesNotSupported", fallback: "The number of reference frames is not supported")
  /// Refresh
  internal static let refresh = L10n.tr("Localizable", "refresh", fallback: "Refresh")
  /// Regular
  internal static let regular = L10n.tr("Localizable", "regular", fallback: "Regular")
  /// Released
  internal static let released = L10n.tr("Localizable", "released", fallback: "Released")
  /// Reload
  internal static let reload = L10n.tr("Localizable", "reload", fallback: "Reload")
  /// Remaining Time
  internal static let remainingTime = L10n.tr("Localizable", "remainingTime", fallback: "Remaining Time")
  /// Remove
  internal static let remove = L10n.tr("Localizable", "remove", fallback: "Remove")
  /// Remove All Servers
  internal static let removeAllServers = L10n.tr("Localizable", "removeAllServers", fallback: "Remove All Servers")
  /// Remove All Users
  internal static let removeAllUsers = L10n.tr("Localizable", "removeAllUsers", fallback: "Remove All Users")
  /// Remove From Resume
  internal static let removeFromResume = L10n.tr("Localizable", "removeFromResume", fallback: "Remove From Resume")
  /// Report an Issue
  internal static let reportIssue = L10n.tr("Localizable", "reportIssue", fallback: "Report an Issue")
  /// Request a Feature
  internal static let requestFeature = L10n.tr("Localizable", "requestFeature", fallback: "Request a Feature")
  /// Reset
  internal static let reset = L10n.tr("Localizable", "reset", fallback: "Reset")
  /// Reset all settings back to defaults.
  internal static let resetAllSettings = L10n.tr("Localizable", "resetAllSettings", fallback: "Reset all settings back to defaults.")
  /// Reset App Settings
  internal static let resetAppSettings = L10n.tr("Localizable", "resetAppSettings", fallback: "Reset App Settings")
  /// Reset User Settings
  internal static let resetUserSettings = L10n.tr("Localizable", "resetUserSettings", fallback: "Reset User Settings")
  /// Restart Server
  internal static let restartServer = L10n.tr("Localizable", "restartServer", fallback: "Restart Server")
  /// Are you sure you want to restart the server?
  internal static let restartWarning = L10n.tr("Localizable", "restartWarning", fallback: "Are you sure you want to restart the server?")
  /// Resume
  internal static let resume = L10n.tr("Localizable", "resume", fallback: "Resume")
  /// Resume 5 Second Offset
  internal static let resume5SecondOffset = L10n.tr("Localizable", "resume5SecondOffset", fallback: "Resume 5 Second Offset")
  /// Resume Offset
  internal static let resumeOffset = L10n.tr("Localizable", "resumeOffset", fallback: "Resume Offset")
  /// Resume content seconds before the recorded resume time
  internal static let resumeOffsetDescription = L10n.tr("Localizable", "resumeOffsetDescription", fallback: "Resume content seconds before the recorded resume time")
  /// Resume Offset
  internal static let resumeOffsetTitle = L10n.tr("Localizable", "resumeOffsetTitle", fallback: "Resume Offset")
  /// Retrieving media information
  internal static let retrievingMediaInformation = L10n.tr("Localizable", "retrievingMediaInformation", fallback: "Retrieving media information")
  /// Retry
  internal static let retry = L10n.tr("Localizable", "retry", fallback: "Retry")
  /// Right
  internal static let `right` = L10n.tr("Localizable", "right", fallback: "Right")
  /// Run
  internal static let run = L10n.tr("Localizable", "run", fallback: "Run")
  /// Running...
  internal static let running = L10n.tr("Localizable", "running", fallback: "Running...")
  /// Runtime
  internal static let runtime = L10n.tr("Localizable", "runtime", fallback: "Runtime")
  /// Scan All Libraries
  internal static let scanAllLibraries = L10n.tr("Localizable", "scanAllLibraries", fallback: "Scan All Libraries")
  /// Scheduled Tasks
  internal static let scheduledTasks = L10n.tr("Localizable", "scheduledTasks", fallback: "Scheduled Tasks")
  /// Scrub Current Time
  internal static let scrubCurrentTime = L10n.tr("Localizable", "scrubCurrentTime", fallback: "Scrub Current Time")
  /// Search
  internal static let search = L10n.tr("Localizable", "search", fallback: "Search")
  /// Search…
  internal static let searchDots = L10n.tr("Localizable", "searchDots", fallback: "Search…")
  /// Searching…
  internal static let searchingDots = L10n.tr("Localizable", "searchingDots", fallback: "Searching…")
  /// Season
  internal static let season = L10n.tr("Localizable", "season", fallback: "Season")
  /// S%1$@:E%2$@
  internal static func seasonAndEpisode(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "seasonAndEpisode", String(describing: p1), String(describing: p2), fallback: "S%1$@:E%2$@")
  }
  /// Seasons
  internal static let seasons = L10n.tr("Localizable", "seasons", fallback: "Seasons")
  /// Secondary audio is not supported
  internal static let secondaryAudioNotSupported = L10n.tr("Localizable", "secondaryAudioNotSupported", fallback: "Secondary audio is not supported")
  /// See All
  internal static let seeAll = L10n.tr("Localizable", "seeAll", fallback: "See All")
  /// Seek Slide Gesture Enabled
  internal static let seekSlideGestureEnabled = L10n.tr("Localizable", "seekSlideGestureEnabled", fallback: "Seek Slide Gesture Enabled")
  /// See More
  internal static let seeMore = L10n.tr("Localizable", "seeMore", fallback: "See More")
  /// Select Cast Destination
  internal static let selectCastDestination = L10n.tr("Localizable", "selectCastDestination", fallback: "Select Cast Destination")
  /// Series
  internal static let series = L10n.tr("Localizable", "series", fallback: "Series")
  /// Series Backdrop
  internal static let seriesBackdrop = L10n.tr("Localizable", "seriesBackdrop", fallback: "Series Backdrop")
  /// Server
  internal static let server = L10n.tr("Localizable", "server", fallback: "Server")
  /// Server %s is already connected
  internal static func serverAlreadyConnected(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "serverAlreadyConnected", p1, fallback: "Server %s is already connected")
  }
  /// Server %s already exists. Add new URL?
  internal static func serverAlreadyExistsPrompt(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "serverAlreadyExistsPrompt", p1, fallback: "Server %s already exists. Add new URL?")
  }
  /// Server Details
  internal static let serverDetails = L10n.tr("Localizable", "serverDetails", fallback: "Server Details")
  /// Server Information
  internal static let serverInformation = L10n.tr("Localizable", "serverInformation", fallback: "Server Information")
  /// Server Logs
  internal static let serverLogs = L10n.tr("Localizable", "serverLogs", fallback: "Server Logs")
  /// Servers
  internal static let servers = L10n.tr("Localizable", "servers", fallback: "Servers")
  /// Server URL
  internal static let serverURL = L10n.tr("Localizable", "serverURL", fallback: "Server URL")
  /// Session
  internal static let session = L10n.tr("Localizable", "session", fallback: "Session")
  /// Settings
  internal static let settings = L10n.tr("Localizable", "settings", fallback: "Settings")
  /// Show Cast & Crew
  internal static let showCastAndCrew = L10n.tr("Localizable", "showCastAndCrew", fallback: "Show Cast & Crew")
  /// Show Chapters Info In Bottom Overlay
  internal static let showChaptersInfoInBottomOverlay = L10n.tr("Localizable", "showChaptersInfoInBottomOverlay", fallback: "Show Chapters Info In Bottom Overlay")
  /// Show Favorited
  internal static let showFavorited = L10n.tr("Localizable", "showFavorited", fallback: "Show Favorited")
  /// Show Favorites
  internal static let showFavorites = L10n.tr("Localizable", "showFavorites", fallback: "Show Favorites")
  /// Flatten Library Items
  internal static let showFlattenView = L10n.tr("Localizable", "showFlattenView", fallback: "Flatten Library Items")
  /// Show Missing Episodes
  internal static let showMissingEpisodes = L10n.tr("Localizable", "showMissingEpisodes", fallback: "Show Missing Episodes")
  /// Show Missing Seasons
  internal static let showMissingSeasons = L10n.tr("Localizable", "showMissingSeasons", fallback: "Show Missing Seasons")
  /// Show Poster Labels
  internal static let showPosterLabels = L10n.tr("Localizable", "showPosterLabels", fallback: "Show Poster Labels")
  /// Show Progress
  internal static let showProgress = L10n.tr("Localizable", "showProgress", fallback: "Show Progress")
  /// Show Recently Added
  internal static let showRecentlyAdded = L10n.tr("Localizable", "showRecentlyAdded", fallback: "Show Recently Added")
  /// Show Unwatched
  internal static let showUnwatched = L10n.tr("Localizable", "showUnwatched", fallback: "Show Unwatched")
  /// Show Watched
  internal static let showWatched = L10n.tr("Localizable", "showWatched", fallback: "Show Watched")
  /// Shutdown Server
  internal static let shutdownServer = L10n.tr("Localizable", "shutdownServer", fallback: "Shutdown Server")
  /// Are you sure you want to shutdown the server?
  internal static let shutdownWarning = L10n.tr("Localizable", "shutdownWarning", fallback: "Are you sure you want to shutdown the server?")
  /// Signed in as %@
  internal static func signedInAsWithString(_ p1: Any) -> String {
    return L10n.tr("Localizable", "signedInAsWithString", String(describing: p1), fallback: "Signed in as %@")
  }
  /// Sign In
  internal static let signIn = L10n.tr("Localizable", "signIn", fallback: "Sign In")
  /// Sign in to get started
  internal static let signInGetStarted = L10n.tr("Localizable", "signInGetStarted", fallback: "Sign in to get started")
  /// Sign In to %s
  internal static func signInToServer(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "signInToServer", p1, fallback: "Sign In to %s")
  }
  /// Slider
  internal static let slider = L10n.tr("Localizable", "slider", fallback: "Slider")
  /// Slider Color
  internal static let sliderColor = L10n.tr("Localizable", "sliderColor", fallback: "Slider Color")
  /// Slider Type
  internal static let sliderType = L10n.tr("Localizable", "sliderType", fallback: "Slider Type")
  /// Smaller
  internal static let smaller = L10n.tr("Localizable", "smaller", fallback: "Smaller")
  /// Smallest
  internal static let smallest = L10n.tr("Localizable", "smallest", fallback: "Smallest")
  /// Sort
  internal static let sort = L10n.tr("Localizable", "sort", fallback: "Sort")
  /// Sort by
  internal static let sortBy = L10n.tr("Localizable", "sortBy", fallback: "Sort by")
  /// Source Code
  internal static let sourceCode = L10n.tr("Localizable", "sourceCode", fallback: "Source Code")
  /// Special Features
  internal static let specialFeatures = L10n.tr("Localizable", "specialFeatures", fallback: "Special Features")
  /// Sports
  internal static let sports = L10n.tr("Localizable", "sports", fallback: "Sports")
  /// Stop
  internal static let stop = L10n.tr("Localizable", "stop", fallback: "Stop")
  /// Streams
  internal static let streams = L10n.tr("Localizable", "streams", fallback: "Streams")
  /// STUDIO
  internal static let studio = L10n.tr("Localizable", "studio", fallback: "STUDIO")
  /// Studios
  internal static let studios = L10n.tr("Localizable", "studios", fallback: "Studios")
  /// Subtitle
  internal static let subtitle = L10n.tr("Localizable", "subtitle", fallback: "Subtitle")
  /// The subtitle codec is not supported
  internal static let subtitleCodecNotSupported = L10n.tr("Localizable", "subtitleCodecNotSupported", fallback: "The subtitle codec is not supported")
  /// Subtitle Color
  internal static let subtitleColor = L10n.tr("Localizable", "subtitleColor", fallback: "Subtitle Color")
  /// Subtitle Font
  internal static let subtitleFont = L10n.tr("Localizable", "subtitleFont", fallback: "Subtitle Font")
  /// Subtitle Offset
  internal static let subtitleOffset = L10n.tr("Localizable", "subtitleOffset", fallback: "Subtitle Offset")
  /// Subtitles
  internal static let subtitles = L10n.tr("Localizable", "subtitles", fallback: "Subtitles")
  /// Settings only affect some subtitle types
  internal static let subtitlesDisclaimer = L10n.tr("Localizable", "subtitlesDisclaimer", fallback: "Settings only affect some subtitle types")
  /// Subtitle Size
  internal static let subtitleSize = L10n.tr("Localizable", "subtitleSize", fallback: "Subtitle Size")
  /// Suggestions
  internal static let suggestions = L10n.tr("Localizable", "suggestions", fallback: "Suggestions")
  /// Switch User
  internal static let switchUser = L10n.tr("Localizable", "switchUser", fallback: "Switch User")
  /// System
  internal static let system = L10n.tr("Localizable", "system", fallback: "System")
  /// System Control Gestures Enabled
  internal static let systemControlGesturesEnabled = L10n.tr("Localizable", "systemControlGesturesEnabled", fallback: "System Control Gestures Enabled")
  /// Tags
  internal static let tags = L10n.tr("Localizable", "tags", fallback: "Tags")
  /// Task
  internal static let task = L10n.tr("Localizable", "task", fallback: "Task")
  /// Aborted
  internal static let taskAborted = L10n.tr("Localizable", "taskAborted", fallback: "Aborted")
  /// Cancelled
  internal static let taskCancelled = L10n.tr("Localizable", "taskCancelled", fallback: "Cancelled")
  /// Completed
  internal static let taskCompleted = L10n.tr("Localizable", "taskCompleted", fallback: "Completed")
  /// Failed
  internal static let taskFailed = L10n.tr("Localizable", "taskFailed", fallback: "Failed")
  /// Tasks
  internal static let tasks = L10n.tr("Localizable", "tasks", fallback: "Tasks")
  /// Tasks are operations that are scheduled to run periodically or can be triggered manually.
  internal static let tasksDescription = L10n.tr("Localizable", "tasksDescription", fallback: "Tasks are operations that are scheduled to run periodically or can be triggered manually.")
  /// Test Size
  internal static let testSize = L10n.tr("Localizable", "testSize", fallback: "Test Size")
  /// Timestamp
  internal static let timestamp = L10n.tr("Localizable", "timestamp", fallback: "Timestamp")
  /// Timestamp Type
  internal static let timestampType = L10n.tr("Localizable", "timestampType", fallback: "Timestamp Type")
  /// Too Many Redirects
  internal static let tooManyRedirects = L10n.tr("Localizable", "tooManyRedirects", fallback: "Too Many Redirects")
  /// Trailing Value
  internal static let trailingValue = L10n.tr("Localizable", "trailingValue", fallback: "Trailing Value")
  /// Transcode
  internal static let transcode = L10n.tr("Localizable", "transcode", fallback: "Transcode")
  /// Transcode Reason(s)
  internal static let transcodeReasons = L10n.tr("Localizable", "transcodeReasons", fallback: "Transcode Reason(s)")
  /// Transition
  internal static let transition = L10n.tr("Localizable", "transition", fallback: "Transition")
  /// Try again
  internal static let tryAgain = L10n.tr("Localizable", "tryAgain", fallback: "Try again")
  /// TV Shows
  internal static let tvShows = L10n.tr("Localizable", "tvShows", fallback: "TV Shows")
  /// Unable to connect to server
  internal static let unableToConnectServer = L10n.tr("Localizable", "unableToConnectServer", fallback: "Unable to connect to server")
  /// Unable to find host
  internal static let unableToFindHost = L10n.tr("Localizable", "unableToFindHost", fallback: "Unable to find host")
  /// Unaired
  internal static let unaired = L10n.tr("Localizable", "unaired", fallback: "Unaired")
  /// Unauthorized
  internal static let unauthorized = L10n.tr("Localizable", "unauthorized", fallback: "Unauthorized")
  /// Unauthorized user
  internal static let unauthorizedUser = L10n.tr("Localizable", "unauthorizedUser", fallback: "Unauthorized user")
  /// Unknown
  internal static let unknown = L10n.tr("Localizable", "unknown", fallback: "Unknown")
  /// The audio stream information is unknown
  internal static let unknownAudioStreamInfo = L10n.tr("Localizable", "unknownAudioStreamInfo", fallback: "The audio stream information is unknown")
  /// Unknown Error
  internal static let unknownError = L10n.tr("Localizable", "unknownError", fallback: "Unknown Error")
  /// The video stream information is unknown
  internal static let unknownVideoStreamInfo = L10n.tr("Localizable", "unknownVideoStreamInfo", fallback: "The video stream information is unknown")
  /// Unplayed
  internal static let unplayed = L10n.tr("Localizable", "unplayed", fallback: "Unplayed")
  /// URL
  internal static let url = L10n.tr("Localizable", "url", fallback: "URL")
  /// Use as Transcoding Profile
  internal static let useAsTranscodingProfile = L10n.tr("Localizable", "useAsTranscodingProfile", fallback: "Use as Transcoding Profile")
  /// Use Primary Image
  internal static let usePrimaryImage = L10n.tr("Localizable", "usePrimaryImage", fallback: "Use Primary Image")
  /// Uses the primary image and hides the logo.
  internal static let usePrimaryImageDescription = L10n.tr("Localizable", "usePrimaryImageDescription", fallback: "Uses the primary image and hides the logo.")
  /// User
  internal static let user = L10n.tr("Localizable", "user", fallback: "User")
  /// User %s is already signed in
  internal static func userAlreadySignedIn(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "userAlreadySignedIn", p1, fallback: "User %s is already signed in")
  }
  /// Username
  internal static let username = L10n.tr("Localizable", "username", fallback: "Username")
  /// Version
  internal static let version = L10n.tr("Localizable", "version", fallback: "Version")
  /// Video
  internal static let video = L10n.tr("Localizable", "video", fallback: "Video")
  /// The video bit depth is not supported
  internal static let videoBitDepthNotSupported = L10n.tr("Localizable", "videoBitDepthNotSupported", fallback: "The video bit depth is not supported")
  /// The video bitrate is not supported
  internal static let videoBitrateNotSupported = L10n.tr("Localizable", "videoBitrateNotSupported", fallback: "The video bitrate is not supported")
  /// The video codec is not supported
  internal static let videoCodecNotSupported = L10n.tr("Localizable", "videoCodecNotSupported", fallback: "The video codec is not supported")
  /// The video framerate is not supported
  internal static let videoFramerateNotSupported = L10n.tr("Localizable", "videoFramerateNotSupported", fallback: "The video framerate is not supported")
  /// The video level is not supported
  internal static let videoLevelNotSupported = L10n.tr("Localizable", "videoLevelNotSupported", fallback: "The video level is not supported")
  /// Video Player
  internal static let videoPlayer = L10n.tr("Localizable", "videoPlayer", fallback: "Video Player")
  /// Video Player Type
  internal static let videoPlayerType = L10n.tr("Localizable", "videoPlayerType", fallback: "Video Player Type")
  /// The video profile is not supported
  internal static let videoProfileNotSupported = L10n.tr("Localizable", "videoProfileNotSupported", fallback: "The video profile is not supported")
  /// The video range type is not supported
  internal static let videoRangeTypeNotSupported = L10n.tr("Localizable", "videoRangeTypeNotSupported", fallback: "The video range type is not supported")
  /// The video resolution is not supported
  internal static let videoResolutionNotSupported = L10n.tr("Localizable", "videoResolutionNotSupported", fallback: "The video resolution is not supported")
  /// Who's watching?
  internal static let whosWatching = L10n.tr("Localizable", "WhosWatching", fallback: "Who's watching?")
  /// WIP
  internal static let wip = L10n.tr("Localizable", "wip", fallback: "WIP")
  /// Yellow
  internal static let yellow = L10n.tr("Localizable", "yellow", fallback: "Yellow")
  /// Your Favorites
  internal static let yourFavorites = L10n.tr("Localizable", "yourFavorites", fallback: "Your Favorites")
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
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
