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
  /// Absolute
  internal static let absolute = L10n.tr("Localizable", "absolute", fallback: "Absolute")
  /// Accent color
  internal static let accentColor = L10n.tr("Localizable", "accentColor", fallback: "Accent color")
  /// Access
  internal static let access = L10n.tr("Localizable", "access", fallback: "Access")
  /// Accessibility
  internal static let accessibility = L10n.tr("Localizable", "accessibility", fallback: "Accessibility")
  /// The end time must come after the start time.
  internal static let accessScheduleInvalidTime = L10n.tr("Localizable", "accessScheduleInvalidTime", fallback: "The end time must come after the start time.")
  /// Access schedules
  internal static let accessSchedules = L10n.tr("Localizable", "accessSchedules", fallback: "Access schedules")
  /// Define the allowed hours for usage and restrict access outside those times.
  internal static let accessSchedulesDescription = L10n.tr("Localizable", "accessSchedulesDescription", fallback: "Define the allowed hours for usage and restrict access outside those times.")
  /// User will have access to no media unless it contains at least one allowed tag.
  internal static let accessTagAllowDescription = L10n.tr("Localizable", "accessTagAllowDescription", fallback: "User will have access to no media unless it contains at least one allowed tag.")
  /// Access tag already exists
  internal static let accessTagAlreadyExists = L10n.tr("Localizable", "accessTagAlreadyExists", fallback: "Access tag already exists")
  /// User will have access to all media except when it contains any blocked tag.
  internal static let accessTagBlockDescription = L10n.tr("Localizable", "accessTagBlockDescription", fallback: "User will have access to all media except when it contains any blocked tag.")
  /// Access tags
  internal static let accessTags = L10n.tr("Localizable", "accessTags", fallback: "Access tags")
  /// Use tags to grant or restrict this user's access to media.
  internal static let accessTagsDescription = L10n.tr("Localizable", "accessTagsDescription", fallback: "Use tags to grant or restrict this user's access to media.")
  /// Active
  internal static let active = L10n.tr("Localizable", "active", fallback: "Active")
  /// Activity
  internal static let activity = L10n.tr("Localizable", "activity", fallback: "Activity")
  /// Activity log
  internal static let activityLog = L10n.tr("Localizable", "activityLog", fallback: "Activity log")
  /// Actor
  internal static let actor = L10n.tr("Localizable", "actor", fallback: "Actor")
  /// Add
  internal static let add = L10n.tr("Localizable", "add", fallback: "Add")
  /// Add access schedule
  internal static let addAccessSchedule = L10n.tr("Localizable", "addAccessSchedule", fallback: "Add access schedule")
  /// Add access tag
  internal static let addAccessTag = L10n.tr("Localizable", "addAccessTag", fallback: "Add access tag")
  /// Additional security access for users signed in to this device. This does not change any Jellyfin server user settings.
  internal static let additionalSecurityAccessDescription = L10n.tr("Localizable", "additionalSecurityAccessDescription", fallback: "Additional security access for users signed in to this device. This does not change any Jellyfin server user settings.")
  /// Add server
  internal static let addServer = L10n.tr("Localizable", "addServer", fallback: "Add server")
  /// Add trigger
  internal static let addTrigger = L10n.tr("Localizable", "addTrigger", fallback: "Add trigger")
  /// Add URL
  internal static let addURL = L10n.tr("Localizable", "addURL", fallback: "Add URL")
  /// Add user
  internal static let addUser = L10n.tr("Localizable", "addUser", fallback: "Add user")
  /// Administrator
  internal static let administrator = L10n.tr("Localizable", "administrator", fallback: "Administrator")
  /// Advanced
  internal static let advanced = L10n.tr("Localizable", "advanced", fallback: "Advanced")
  /// Age %@
  internal static func agesGroup(_ p1: Any) -> String {
    return L10n.tr("Localizable", "agesGroup", String(describing: p1), fallback: "Age %@")
  }
  /// Aggregate folder
  internal static let aggregateFolder = L10n.tr("Localizable", "aggregateFolder", fallback: "Aggregate folder")
  /// Aggregate folders
  internal static let aggregateFolders = L10n.tr("Localizable", "aggregateFolders", fallback: "Aggregate folders")
  /// Aired
  internal static let aired = L10n.tr("Localizable", "aired", fallback: "Aired")
  /// Aired episode order
  internal static let airedEpisodeOrder = L10n.tr("Localizable", "airedEpisodeOrder", fallback: "Aired episode order")
  /// Air time
  internal static let airTime = L10n.tr("Localizable", "airTime", fallback: "Air time")
  /// Airs %s
  internal static func airWithDate(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "airWithDate", p1, fallback: "Airs %s")
  }
  /// Album
  internal static let album = L10n.tr("Localizable", "album", fallback: "Album")
  /// Album artist
  internal static let albumArtist = L10n.tr("Localizable", "albumArtist", fallback: "Album artist")
  /// Albums
  internal static let albums = L10n.tr("Localizable", "albums", fallback: "Albums")
  /// All
  internal static let all = L10n.tr("Localizable", "all", fallback: "All")
  /// All audiences
  internal static let allAudiences = L10n.tr("Localizable", "allAudiences", fallback: "All audiences")
  /// View all past and present devices that have connected.
  internal static let allDevicesDescription = L10n.tr("Localizable", "allDevicesDescription", fallback: "View all past and present devices that have connected.")
  /// All languages
  internal static let allLanguages = L10n.tr("Localizable", "allLanguages", fallback: "All languages")
  /// All media
  internal static let allMedia = L10n.tr("Localizable", "allMedia", fallback: "All media")
  /// Allowed
  internal static let allowed = L10n.tr("Localizable", "allowed", fallback: "Allowed")
  /// All servers
  internal static let allServers = L10n.tr("Localizable", "allServers", fallback: "All servers")
  /// View and manage all registered users on the server, including their permissions and activity status.
  internal static let allUsersDescription = L10n.tr("Localizable", "allUsersDescription", fallback: "View and manage all registered users on the server, including their permissions and activity status.")
  /// Alternate
  internal static let alternate = L10n.tr("Localizable", "alternate", fallback: "Alternate")
  /// Alternate DVD
  internal static let alternateDVD = L10n.tr("Localizable", "alternateDVD", fallback: "Alternate DVD")
  /// Anamorphic video is not supported
  internal static let anamorphicVideoNotSupported = L10n.tr("Localizable", "anamorphicVideoNotSupported", fallback: "Anamorphic video is not supported")
  /// API key copied
  internal static let apiKeyCopied = L10n.tr("Localizable", "apiKeyCopied", fallback: "API key copied")
  /// Your API key was copied to your clipboard!
  internal static let apiKeyCopiedMessage = L10n.tr("Localizable", "apiKeyCopiedMessage", fallback: "Your API key was copied to your clipboard!")
  /// API keys
  internal static let apiKeys = L10n.tr("Localizable", "apiKeys", fallback: "API keys")
  /// API Keys
  internal static let apiKeysCapitalized = L10n.tr("Localizable", "apiKeysCapitalized", fallback: "API Keys")
  /// External applications require an API key to communicate with your server.
  internal static let apiKeysDescription = L10n.tr("Localizable", "apiKeysDescription", fallback: "External applications require an API key to communicate with your server.")
  /// Appearance
  internal static let appearance = L10n.tr("Localizable", "appearance", fallback: "Appearance")
  /// App icon
  internal static let appIcon = L10n.tr("Localizable", "appIcon", fallback: "App icon")
  /// Application name
  internal static let applicationName = L10n.tr("Localizable", "applicationName", fallback: "Application name")
  /// Arranger
  internal static let arranger = L10n.tr("Localizable", "arranger", fallback: "Arranger")
  /// Art
  internal static let art = L10n.tr("Localizable", "art", fallback: "Art")
  /// Artist
  internal static let artist = L10n.tr("Localizable", "artist", fallback: "Artist")
  /// Artists
  internal static let artists = L10n.tr("Localizable", "artists", fallback: "Artists")
  /// Ascending
  internal static let ascending = L10n.tr("Localizable", "ascending", fallback: "Ascending")
  /// Aspect fill
  internal static let aspectFill = L10n.tr("Localizable", "aspectFill", fallback: "Aspect fill")
  /// Audio
  internal static let audio = L10n.tr("Localizable", "audio", fallback: "Audio")
  /// The audio bit depth is not supported
  internal static let audioBitDepthNotSupported = L10n.tr("Localizable", "audioBitDepthNotSupported", fallback: "The audio bit depth is not supported")
  /// The audio bitrate is not supported
  internal static let audioBitrateNotSupported = L10n.tr("Localizable", "audioBitrateNotSupported", fallback: "The audio bitrate is not supported")
  /// Audio book
  internal static let audioBook = L10n.tr("Localizable", "audioBook", fallback: "Audio book")
  /// Audio books
  internal static let audioBooks = L10n.tr("Localizable", "audioBooks", fallback: "Audio books")
  /// The number of audio channels is not supported
  internal static let audioChannelsNotSupported = L10n.tr("Localizable", "audioChannelsNotSupported", fallback: "The number of audio channels is not supported")
  /// The audio codec is not supported
  internal static let audioCodecNotSupported = L10n.tr("Localizable", "audioCodecNotSupported", fallback: "The audio codec is not supported")
  /// The audio track is external and requires transcoding
  internal static let audioIsExternal = L10n.tr("Localizable", "audioIsExternal", fallback: "The audio track is external and requires transcoding")
  /// The audio profile is not supported
  internal static let audioProfileNotSupported = L10n.tr("Localizable", "audioProfileNotSupported", fallback: "The audio profile is not supported")
  /// The audio sample rate is not supported
  internal static let audioSampleRateNotSupported = L10n.tr("Localizable", "audioSampleRateNotSupported", fallback: "The audio sample rate is not supported")
  /// Audio transcoding
  internal static let audioTranscoding = L10n.tr("Localizable", "audioTranscoding", fallback: "Audio transcoding")
  /// Author
  internal static let author = L10n.tr("Localizable", "author", fallback: "Author")
  /// Authorize
  internal static let authorize = L10n.tr("Localizable", "authorize", fallback: "Authorize")
  /// Auto
  internal static let auto = L10n.tr("Localizable", "auto", fallback: "Auto")
  /// Optimizes playback using default settings for most devices. Some formats may require server transcoding for non-compatible media types.
  internal static let autoDescription = L10n.tr("Localizable", "autoDescription", fallback: "Optimizes playback using default settings for most devices. Some formats may require server transcoding for non-compatible media types.")
  /// Auto play
  internal static let autoPlay = L10n.tr("Localizable", "autoPlay", fallback: "Auto play")
  /// Backdrop
  internal static let backdrop = L10n.tr("Localizable", "backdrop", fallback: "Backdrop")
  /// Banner
  internal static let banner = L10n.tr("Localizable", "banner", fallback: "Banner")
  /// Bar buttons
  internal static let barButtons = L10n.tr("Localizable", "barButtons", fallback: "Bar buttons")
  /// Plugin folder
  internal static let basePluginFolder = L10n.tr("Localizable", "basePluginFolder", fallback: "Plugin folder")
  /// Plugin folders
  internal static let basePluginFolders = L10n.tr("Localizable", "basePluginFolders", fallback: "Plugin folders")
  /// Behavior
  internal static let behavior = L10n.tr("Localizable", "behavior", fallback: "Behavior")
  /// Behind the scenes
  internal static let behindTheScenes = L10n.tr("Localizable", "behindTheScenes", fallback: "Behind the scenes")
  /// Tests your server connection to assess internet speed and adjust bandwidth automatically.
  internal static let birateAutoDescription = L10n.tr("Localizable", "birateAutoDescription", fallback: "Tests your server connection to assess internet speed and adjust bandwidth automatically.")
  /// Birthday
  internal static let birthday = L10n.tr("Localizable", "birthday", fallback: "Birthday")
  /// Birthplace
  internal static let birthplace = L10n.tr("Localizable", "birthplace", fallback: "Birthplace")
  /// Birth year
  internal static let birthYear = L10n.tr("Localizable", "birthYear", fallback: "Birth year")
  /// Auto
  internal static let bitrateAuto = L10n.tr("Localizable", "bitrateAuto", fallback: "Auto")
  /// Default bitrate
  internal static let bitrateDefault = L10n.tr("Localizable", "bitrateDefault", fallback: "Default bitrate")
  /// Limits the internet bandwidth used during playback.
  internal static let bitrateDefaultDescription = L10n.tr("Localizable", "bitrateDefaultDescription", fallback: "Limits the internet bandwidth used during playback.")
  /// 480p - 1.5 Mbps
  internal static let bitrateKbps1500 = L10n.tr("Localizable", "bitrateKbps1500", fallback: "480p - 1.5 Mbps")
  /// 360p - 420 Kbps
  internal static let bitrateKbps420 = L10n.tr("Localizable", "bitrateKbps420", fallback: "360p - 420 Kbps")
  /// 480p - 720 Kbps
  internal static let bitrateKbps720 = L10n.tr("Localizable", "bitrateKbps720", fallback: "480p - 720 Kbps")
  /// Maximum
  internal static let bitrateMax = L10n.tr("Localizable", "bitrateMax", fallback: "Maximum")
  /// Maximizes bandwidth usage, up to %@, for each playback stream to ensure the highest quality.
  internal static func bitrateMaxDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "bitrateMaxDescription", String(describing: p1), fallback: "Maximizes bandwidth usage, up to %@, for each playback stream to ensure the highest quality.")
  }
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
  /// Bitrate test
  internal static let bitrateTest = L10n.tr("Localizable", "bitrateTest", fallback: "Bitrate test")
  /// Longer tests are more accurate but may result in a delayed playback.
  internal static let bitrateTestDisclaimer = L10n.tr("Localizable", "bitrateTestDisclaimer", fallback: "Longer tests are more accurate but may result in a delayed playback.")
  /// bps
  internal static let bitsPerSecond = L10n.tr("Localizable", "bitsPerSecond", fallback: "bps")
  /// Blocked
  internal static let blocked = L10n.tr("Localizable", "blocked", fallback: "Blocked")
  /// Block unrated items
  internal static let blockUnratedItems = L10n.tr("Localizable", "blockUnratedItems", fallback: "Block unrated items")
  /// Block items from this user with no or unrecognized rating information.
  internal static let blockUnratedItemsDescription = L10n.tr("Localizable", "blockUnratedItemsDescription", fallback: "Block items from this user with no or unrecognized rating information.")
  /// Blue
  internal static let blue = L10n.tr("Localizable", "blue", fallback: "Blue")
  /// Book
  internal static let book = L10n.tr("Localizable", "book", fallback: "Book")
  /// Books
  internal static let books = L10n.tr("Localizable", "books", fallback: "Books")
  /// Born
  internal static let born = L10n.tr("Localizable", "born", fallback: "Born")
  /// Box
  internal static let box = L10n.tr("Localizable", "box", fallback: "Box")
  /// Box rear
  internal static let boxRear = L10n.tr("Localizable", "boxRear", fallback: "Box rear")
  /// Brightness
  internal static let brightness = L10n.tr("Localizable", "brightness", fallback: "Brightness")
  /// Bugs and features
  internal static let bugsAndFeatures = L10n.tr("Localizable", "bugsAndFeatures", fallback: "Bugs and features")
  /// Buttons
  internal static let buttons = L10n.tr("Localizable", "buttons", fallback: "Buttons")
  /// Cancel
  internal static let cancel = L10n.tr("Localizable", "cancel", fallback: "Cancel")
  /// Cancelling...
  internal static let cancelling = L10n.tr("Localizable", "cancelling", fallback: "Cancelling...")
  /// Cannot connect to host
  internal static let cannotConnectToHost = L10n.tr("Localizable", "cannotConnectToHost", fallback: "Cannot connect to host")
  /// Capabilities
  internal static let capabilities = L10n.tr("Localizable", "capabilities", fallback: "Capabilities")
  /// Cast & crew
  internal static let castAndCrew = L10n.tr("Localizable", "castAndCrew", fallback: "Cast & crew")
  /// Category
  internal static let category = L10n.tr("Localizable", "category", fallback: "Category")
  /// Change pin
  internal static let changePin = L10n.tr("Localizable", "changePin", fallback: "Change pin")
  /// Channel
  internal static let channel = L10n.tr("Localizable", "channel", fallback: "Channel")
  /// Channel display
  internal static let channelDisplay = L10n.tr("Localizable", "channelDisplay", fallback: "Channel display")
  /// Channel folder item
  internal static let channelFolderItem = L10n.tr("Localizable", "channelFolderItem", fallback: "Channel folder item")
  /// Channel folder items
  internal static let channelFolderItems = L10n.tr("Localizable", "channelFolderItems", fallback: "Channel folder items")
  /// Channels
  internal static let channels = L10n.tr("Localizable", "channels", fallback: "Channels")
  /// Chapter
  internal static let chapter = L10n.tr("Localizable", "chapter", fallback: "Chapter")
  /// Chapters
  internal static let chapters = L10n.tr("Localizable", "chapters", fallback: "Chapters")
  /// Chapter slider
  internal static let chapterSlider = L10n.tr("Localizable", "chapterSlider", fallback: "Chapter slider")
  /// Cinematic
  internal static let cinematic = L10n.tr("Localizable", "cinematic", fallback: "Cinematic")
  /// Cinematic background
  internal static let cinematicBackground = L10n.tr("Localizable", "cinematicBackground", fallback: "Cinematic background")
  /// Client
  internal static let client = L10n.tr("Localizable", "client", fallback: "Client")
  /// Clip
  internal static let clip = L10n.tr("Localizable", "clip", fallback: "Clip")
  /// Close
  internal static let close = L10n.tr("Localizable", "close", fallback: "Close")
  /// Collection
  internal static let collection = L10n.tr("Localizable", "collection", fallback: "Collection")
  /// Collection folder
  internal static let collectionFolder = L10n.tr("Localizable", "collectionFolder", fallback: "Collection folder")
  /// Collection folders
  internal static let collectionFolders = L10n.tr("Localizable", "collectionFolders", fallback: "Collection folders")
  /// Collections
  internal static let collections = L10n.tr("Localizable", "collections", fallback: "Collections")
  /// Color
  internal static let color = L10n.tr("Localizable", "color", fallback: "Color")
  /// Colorist
  internal static let colorist = L10n.tr("Localizable", "colorist", fallback: "Colorist")
  /// Columns
  internal static let columns = L10n.tr("Localizable", "columns", fallback: "Columns")
  /// Columns: %@
  internal static func columnsWithCount(_ p1: Any) -> String {
    return L10n.tr("Localizable", "columnsWithCount", String(describing: p1), fallback: "Columns: %@")
  }
  /// Community
  internal static let community = L10n.tr("Localizable", "community", fallback: "Community")
  /// Community rating
  internal static let communityRating = L10n.tr("Localizable", "communityRating", fallback: "Community rating")
  /// Community rating on a scale from 1 to 10.
  internal static let communityRatingDescription = L10n.tr("Localizable", "communityRatingDescription", fallback: "Community rating on a scale from 1 to 10.")
  /// Compact
  internal static let compact = L10n.tr("Localizable", "compact", fallback: "Compact")
  /// Compact logo
  internal static let compactLogo = L10n.tr("Localizable", "compactLogo", fallback: "Compact logo")
  /// Compact poster
  internal static let compactPoster = L10n.tr("Localizable", "compactPoster", fallback: "Compact poster")
  /// Compatibility
  internal static let compatibility = L10n.tr("Localizable", "compatibility", fallback: "Compatibility")
  /// Most compatible
  internal static let compatible = L10n.tr("Localizable", "compatible", fallback: "Most compatible")
  /// Converts all media to H.264 video and AAC audio for maximum compatibility. May require server transcoding for non-compatible media types.
  internal static let compatibleDescription = L10n.tr("Localizable", "compatibleDescription", fallback: "Converts all media to H.264 video and AAC audio for maximum compatibility. May require server transcoding for non-compatible media types.")
  /// Composer
  internal static let composer = L10n.tr("Localizable", "composer", fallback: "Composer")
  /// Conductor
  internal static let conductor = L10n.tr("Localizable", "conductor", fallback: "Conductor")
  /// Confirm
  internal static let confirm = L10n.tr("Localizable", "confirm", fallback: "Confirm")
  /// Are you sure you want to delete %@ and all of its connected users?
  internal static func confirmDeleteServerAndUsers(_ p1: Any) -> String {
    return L10n.tr("Localizable", "confirmDeleteServerAndUsers", String(describing: p1), fallback: "Are you sure you want to delete %@ and all of its connected users?")
  }
  /// Confirm new password
  internal static let confirmNewPassword = L10n.tr("Localizable", "confirmNewPassword", fallback: "Confirm new password")
  /// Confirm password
  internal static let confirmPassword = L10n.tr("Localizable", "confirmPassword", fallback: "Confirm password")
  /// Connect
  internal static let connect = L10n.tr("Localizable", "connect", fallback: "Connect")
  /// Connect to a Jellyfin server to get started
  internal static let connectToJellyfinServerStart = L10n.tr("Localizable", "connectToJellyfinServerStart", fallback: "Connect to a Jellyfin server to get started")
  /// Connect to server
  internal static let connectToServer = L10n.tr("Localizable", "connectToServer", fallback: "Connect to server")
  /// The container bitrate exceeds the allowed limit
  internal static let containerBitrateExceedsLimit = L10n.tr("Localizable", "containerBitrateExceedsLimit", fallback: "The container bitrate exceeds the allowed limit")
  /// The container format is not supported
  internal static let containerNotSupported = L10n.tr("Localizable", "containerNotSupported", fallback: "The container format is not supported")
  /// Containers
  internal static let containers = L10n.tr("Localizable", "containers", fallback: "Containers")
  /// Continue
  internal static let `continue` = L10n.tr("Localizable", "continue", fallback: "Continue")
  /// Continuing
  internal static let continuing = L10n.tr("Localizable", "continuing", fallback: "Continuing")
  /// Control other users
  internal static let controlOtherUsers = L10n.tr("Localizable", "controlOtherUsers", fallback: "Control other users")
  /// Control shared devices
  internal static let controlSharedDevices = L10n.tr("Localizable", "controlSharedDevices", fallback: "Control shared devices")
  /// Country
  internal static let country = L10n.tr("Localizable", "country", fallback: "Country")
  /// Cover artist
  internal static let coverArtist = L10n.tr("Localizable", "coverArtist", fallback: "Cover artist")
  /// Create & join groups
  internal static let createAndJoinGroups = L10n.tr("Localizable", "createAndJoinGroups", fallback: "Create & join groups")
  /// Create API Key
  internal static let createAPIKeyCapitalized = L10n.tr("Localizable", "createAPIKeyCapitalized", fallback: "Create API Key")
  /// Enter the application name for the new API key.
  internal static let createAPIKeyMessage = L10n.tr("Localizable", "createAPIKeyMessage", fallback: "Enter the application name for the new API key.")
  /// Create a pin to sign in to %@ on this device
  internal static func createPinForUser(_ p1: Any) -> String {
    return L10n.tr("Localizable", "createPinForUser", String(describing: p1), fallback: "Create a pin to sign in to %@ on this device")
  }
  /// Creator
  internal static let creator = L10n.tr("Localizable", "creator", fallback: "Creator")
  /// Critic rating
  internal static let criticRating = L10n.tr("Localizable", "criticRating", fallback: "Critic rating")
  /// Critic rating on a scale from 1 to 100.
  internal static let criticRatingDescription = L10n.tr("Localizable", "criticRatingDescription", fallback: "Critic rating on a scale from 1 to 100.")
  /// Critics
  internal static let critics = L10n.tr("Localizable", "critics", fallback: "Critics")
  /// Current password
  internal static let currentPassword = L10n.tr("Localizable", "currentPassword", fallback: "Current password")
  /// Custom
  internal static let custom = L10n.tr("Localizable", "custom", fallback: "Custom")
  /// Custom bitrate
  internal static let customBitrate = L10n.tr("Localizable", "customBitrate", fallback: "Custom bitrate")
  /// Manually set the maximum number of connections a user can have to the server.
  internal static let customConnectionsDescription = L10n.tr("Localizable", "customConnectionsDescription", fallback: "Manually set the maximum number of connections a user can have to the server.")
  /// Allows advanced customization of device profiles for native playback. Incorrect settings may affect playback.
  internal static let customDescription = L10n.tr("Localizable", "customDescription", fallback: "Allows advanced customization of device profiles for native playback. Incorrect settings may affect playback.")
  /// The custom device profiles will be added to the default Swiftfin device profiles.
  internal static let customDeviceProfileAdd = L10n.tr("Localizable", "customDeviceProfileAdd", fallback: "The custom device profiles will be added to the default Swiftfin device profiles.")
  /// The custom device profiles will replace the default Swiftfin device profiles.
  internal static let customDeviceProfileReplace = L10n.tr("Localizable", "customDeviceProfileReplace", fallback: "The custom device profiles will replace the default Swiftfin device profiles.")
  /// Manually set the number of failed login attempts allowed before locking the user.
  internal static let customFailedLoginDescription = L10n.tr("Localizable", "customFailedLoginDescription", fallback: "Manually set the number of failed login attempts allowed before locking the user.")
  /// Custom failed logins
  internal static let customFailedLogins = L10n.tr("Localizable", "customFailedLogins", fallback: "Custom failed logins")
  /// Customize
  internal static let customize = L10n.tr("Localizable", "customize", fallback: "Customize")
  /// Custom name
  internal static let customName = L10n.tr("Localizable", "customName", fallback: "Custom name")
  /// Custom profile
  internal static let customProfile = L10n.tr("Localizable", "customProfile", fallback: "Custom profile")
  /// Custom rating
  internal static let customRating = L10n.tr("Localizable", "customRating", fallback: "Custom rating")
  /// Custom sessions
  internal static let customSessions = L10n.tr("Localizable", "customSessions", fallback: "Custom sessions")
  /// Daily
  internal static let daily = L10n.tr("Localizable", "daily", fallback: "Daily")
  /// Dark
  internal static let dark = L10n.tr("Localizable", "dark", fallback: "Dark")
  /// Dashboard
  internal static let dashboard = L10n.tr("Localizable", "dashboard", fallback: "Dashboard")
  /// Perform administrative tasks for your Jellyfin server.
  internal static let dashboardDescription = L10n.tr("Localizable", "dashboardDescription", fallback: "Perform administrative tasks for your Jellyfin server.")
  /// Date
  internal static let date = L10n.tr("Localizable", "date", fallback: "Date")
  /// Date added
  internal static let dateAdded = L10n.tr("Localizable", "dateAdded", fallback: "Date added")
  /// Date created
  internal static let dateCreated = L10n.tr("Localizable", "dateCreated", fallback: "Date created")
  /// Date modified
  internal static let dateModified = L10n.tr("Localizable", "dateModified", fallback: "Date modified")
  /// Date of death
  internal static let dateOfDeath = L10n.tr("Localizable", "dateOfDeath", fallback: "Date of death")
  /// Date played
  internal static let datePlayed = L10n.tr("Localizable", "datePlayed", fallback: "Date played")
  /// Dates
  internal static let dates = L10n.tr("Localizable", "dates", fallback: "Dates")
  /// Day of week
  internal static let dayOfWeek = L10n.tr("Localizable", "dayOfWeek", fallback: "Day of week")
  /// Days
  internal static let days = L10n.tr("Localizable", "days", fallback: "Days")
  /// Default
  internal static let `default` = L10n.tr("Localizable", "default", fallback: "Default")
  /// Admins are locked out after 5 failed attempts. Non-admins are locked out after 3 attempts.
  internal static let defaultFailedLoginDescription = L10n.tr("Localizable", "defaultFailedLoginDescription", fallback: "Admins are locked out after 5 failed attempts. Non-admins are locked out after 3 attempts.")
  /// Delete
  internal static let delete = L10n.tr("Localizable", "delete", fallback: "Delete")
  /// Failed to delete device
  internal static let deleteDeviceFailed = L10n.tr("Localizable", "deleteDeviceFailed", fallback: "Failed to delete device")
  /// Cannot delete a session from the same device (%1$@).
  internal static func deleteDeviceSelfDeletion(_ p1: Any) -> String {
    return L10n.tr("Localizable", "deleteDeviceSelfDeletion", String(describing: p1), fallback: "Cannot delete a session from the same device (%1$@).")
  }
  /// Are you sure you wish to delete this device? This session will be logged out.
  internal static let deleteDeviceWarning = L10n.tr("Localizable", "deleteDeviceWarning", fallback: "Are you sure you wish to delete this device? This session will be logged out.")
  /// Deleted Scene
  internal static let deletedScene = L10n.tr("Localizable", "deletedScene", fallback: "Deleted Scene")
  /// Are you sure you want to delete this item?
  internal static let deleteItemConfirmation = L10n.tr("Localizable", "deleteItemConfirmation", fallback: "Are you sure you want to delete this item?")
  /// Are you sure you want to delete this item? This action cannot be undone.
  internal static let deleteItemConfirmationMessage = L10n.tr("Localizable", "deleteItemConfirmationMessage", fallback: "Are you sure you want to delete this item? This action cannot be undone.")
  /// Delete media
  internal static let deleteMedia = L10n.tr("Localizable", "deleteMedia", fallback: "Delete media")
  /// Are you sure you want to delete the selected items?
  internal static let deleteSelectedConfirmation = L10n.tr("Localizable", "deleteSelectedConfirmation", fallback: "Are you sure you want to delete the selected items?")
  /// Are you sure you wish to delete all selected devices? All selected sessions will be logged out.
  internal static let deleteSelectionDevicesWarning = L10n.tr("Localizable", "deleteSelectionDevicesWarning", fallback: "Are you sure you wish to delete all selected devices? All selected sessions will be logged out.")
  /// Are you sure you wish to delete all selected users?
  internal static let deleteSelectionUsersWarning = L10n.tr("Localizable", "deleteSelectionUsersWarning", fallback: "Are you sure you wish to delete all selected users?")
  /// Delete server
  internal static let deleteServer = L10n.tr("Localizable", "deleteServer", fallback: "Delete server")
  /// Delete user
  internal static let deleteUser = L10n.tr("Localizable", "deleteUser", fallback: "Delete user")
  /// Failed to delete user
  internal static let deleteUserFailed = L10n.tr("Localizable", "deleteUserFailed", fallback: "Failed to delete user")
  /// Are you sure you want to delete %d users?
  internal static func deleteUserMultipleConfirmation(_ p1: Int) -> String {
    return L10n.tr("Localizable", "deleteUserMultipleConfirmation", p1, fallback: "Are you sure you want to delete %d users?")
  }
  /// Cannot delete a user from the same user (%1$@).
  internal static func deleteUserSelfDeletion(_ p1: Any) -> String {
    return L10n.tr("Localizable", "deleteUserSelfDeletion", String(describing: p1), fallback: "Cannot delete a user from the same user (%1$@).")
  }
  /// Are you sure you want to delete %@?
  internal static func deleteUserSingleConfirmation(_ p1: Any) -> String {
    return L10n.tr("Localizable", "deleteUserSingleConfirmation", String(describing: p1), fallback: "Are you sure you want to delete %@?")
  }
  /// Are you sure you wish to delete this user?
  internal static let deleteUserWarning = L10n.tr("Localizable", "deleteUserWarning", fallback: "Are you sure you wish to delete this user?")
  /// Deletion
  internal static let deletion = L10n.tr("Localizable", "deletion", fallback: "Deletion")
  /// Delivery
  internal static let delivery = L10n.tr("Localizable", "delivery", fallback: "Delivery")
  /// Descending
  internal static let descending = L10n.tr("Localizable", "descending", fallback: "Descending")
  /// Detailed
  internal static let detailed = L10n.tr("Localizable", "detailed", fallback: "Detailed")
  /// Details
  internal static let details = L10n.tr("Localizable", "details", fallback: "Details")
  /// Device
  internal static let device = L10n.tr("Localizable", "device", fallback: "Device")
  /// Device access
  internal static let deviceAccess = L10n.tr("Localizable", "deviceAccess", fallback: "Device access")
  /// Device authentication
  internal static let deviceAuth = L10n.tr("Localizable", "deviceAuth", fallback: "Device authentication")
  /// Device authentication failed
  internal static let deviceAuthFailed = L10n.tr("Localizable", "deviceAuthFailed", fallback: "Device authentication failed")
  /// Device profile
  internal static let deviceProfile = L10n.tr("Localizable", "deviceProfile", fallback: "Device profile")
  /// Decide which media plays natively or requires server transcoding for compatibility.
  internal static let deviceProfileDescription = L10n.tr("Localizable", "deviceProfileDescription", fallback: "Decide which media plays natively or requires server transcoding for compatibility.")
  /// Devices
  internal static let devices = L10n.tr("Localizable", "devices", fallback: "Devices")
  /// Died
  internal static let died = L10n.tr("Localizable", "died", fallback: "Died")
  /// Digital
  internal static let digital = L10n.tr("Localizable", "digital", fallback: "Digital")
  /// Dimensions
  internal static let dimensions = L10n.tr("Localizable", "dimensions", fallback: "Dimensions")
  /// Plays content in its original format. May cause playback issues on unsupported media types.
  internal static let directDescription = L10n.tr("Localizable", "directDescription", fallback: "Plays content in its original format. May cause playback issues on unsupported media types.")
  /// Director
  internal static let director = L10n.tr("Localizable", "director", fallback: "Director")
  /// Direct play
  internal static let directPlay = L10n.tr("Localizable", "directPlay", fallback: "Direct play")
  /// An error occurred during direct play
  internal static let directPlayError = L10n.tr("Localizable", "directPlayError", fallback: "An error occurred during direct play")
  /// Direct Stream
  internal static let directStream = L10n.tr("Localizable", "directStream", fallback: "Direct Stream")
  /// Disabled
  internal static let disabled = L10n.tr("Localizable", "disabled", fallback: "Disabled")
  /// Disc
  internal static let disc = L10n.tr("Localizable", "disc", fallback: "Disc")
  /// Disclaimer
  internal static let disclaimer = L10n.tr("Localizable", "disclaimer", fallback: "Disclaimer")
  /// Dismiss
  internal static let dismiss = L10n.tr("Localizable", "dismiss", fallback: "Dismiss")
  /// Display order
  internal static let displayOrder = L10n.tr("Localizable", "displayOrder", fallback: "Display order")
  /// Done
  internal static let done = L10n.tr("Localizable", "done", fallback: "Done")
  /// Double touch
  internal static let doubleTouch = L10n.tr("Localizable", "doubleTouch", fallback: "Double touch")
  /// Downloads
  internal static let downloads = L10n.tr("Localizable", "downloads", fallback: "Downloads")
  /// Duplicate user
  internal static let duplicateUser = L10n.tr("Localizable", "duplicateUser", fallback: "Duplicate user")
  /// %@ is already saved
  internal static func duplicateUserSaved(_ p1: Any) -> String {
    return L10n.tr("Localizable", "duplicateUserSaved", String(describing: p1), fallback: "%@ is already saved")
  }
  /// Duration
  internal static let duration = L10n.tr("Localizable", "duration", fallback: "Duration")
  /// DVD
  internal static let dvd = L10n.tr("Localizable", "dvd", fallback: "DVD")
  /// Edit
  internal static let edit = L10n.tr("Localizable", "edit", fallback: "Edit")
  /// Edit collections
  internal static let editCollections = L10n.tr("Localizable", "editCollections", fallback: "Edit collections")
  /// Edit media
  internal static let editMedia = L10n.tr("Localizable", "editMedia", fallback: "Edit media")
  /// Editor
  internal static let editor = L10n.tr("Localizable", "editor", fallback: "Editor")
  /// Edit server
  internal static let editServer = L10n.tr("Localizable", "editServer", fallback: "Edit server")
  /// Edit users
  internal static let editUsers = L10n.tr("Localizable", "editUsers", fallback: "Edit users")
  /// Embedded
  internal static let embedded = L10n.tr("Localizable", "embedded", fallback: "Embedded")
  /// Embedded subtitles cannot be edited.
  internal static let embeddedSubtitleFooter = L10n.tr("Localizable", "embeddedSubtitleFooter", fallback: "Embedded subtitles cannot be edited.")
  /// Enable all devices
  internal static let enableAllDevices = L10n.tr("Localizable", "enableAllDevices", fallback: "Enable all devices")
  /// Enable all libraries
  internal static let enableAllLibraries = L10n.tr("Localizable", "enableAllLibraries", fallback: "Enable all libraries")
  /// Enabled
  internal static let enabled = L10n.tr("Localizable", "enabled", fallback: "Enabled")
  /// Enabled trailers
  internal static let enabledTrailers = L10n.tr("Localizable", "enabledTrailers", fallback: "Enabled trailers")
  /// End date
  internal static let endDate = L10n.tr("Localizable", "endDate", fallback: "End date")
  /// Ended
  internal static let ended = L10n.tr("Localizable", "ended", fallback: "Ended")
  /// End time
  internal static let endTime = L10n.tr("Localizable", "endTime", fallback: "End time")
  /// Engineer
  internal static let engineer = L10n.tr("Localizable", "engineer", fallback: "Engineer")
  /// Enter custom bitrate in Mbps
  internal static let enterCustomBitrate = L10n.tr("Localizable", "enterCustomBitrate", fallback: "Enter custom bitrate in Mbps")
  /// Enter custom failed logins limit
  internal static let enterCustomFailedLogins = L10n.tr("Localizable", "enterCustomFailedLogins", fallback: "Enter custom failed logins limit")
  /// Enter custom max sessions
  internal static let enterCustomMaxSessions = L10n.tr("Localizable", "enterCustomMaxSessions", fallback: "Enter custom max sessions")
  /// Enter the episode number.
  internal static let enterEpisodeNumber = L10n.tr("Localizable", "enterEpisodeNumber", fallback: "Enter the episode number.")
  /// Enter pin
  internal static let enterPin = L10n.tr("Localizable", "enterPin", fallback: "Enter pin")
  /// Enter pin for %@
  internal static func enterPinForUser(_ p1: Any) -> String {
    return L10n.tr("Localizable", "enterPinForUser", String(describing: p1), fallback: "Enter pin for %@")
  }
  /// Enter the season number.
  internal static let enterSeasonNumber = L10n.tr("Localizable", "enterSeasonNumber", fallback: "Enter the season number.")
  /// Episode
  internal static let episode = L10n.tr("Localizable", "episode", fallback: "Episode")
  /// Episode Landscape Poster
  internal static let episodeLandscapePoster = L10n.tr("Localizable", "episodeLandscapePoster", fallback: "Episode Landscape Poster")
  /// Episode %1$@
  internal static func episodeNumber(_ p1: Any) -> String {
    return L10n.tr("Localizable", "episodeNumber", String(describing: p1), fallback: "Episode %1$@")
  }
  /// Episode runtime in minutes.
  internal static let episodeRuntimeDescription = L10n.tr("Localizable", "episodeRuntimeDescription", fallback: "Episode runtime in minutes.")
  /// Episodes
  internal static let episodes = L10n.tr("Localizable", "episodes", fallback: "Episodes")
  /// Error
  internal static let error = L10n.tr("Localizable", "error", fallback: "Error")
  /// Error details
  internal static let errorDetails = L10n.tr("Localizable", "errorDetails", fallback: "Error details")
  /// Every
  internal static let every = L10n.tr("Localizable", "every", fallback: "Every")
  /// Everyday
  internal static let everyday = L10n.tr("Localizable", "everyday", fallback: "Everyday")
  /// Every %1$@
  internal static func everyInterval(_ p1: Any) -> String {
    return L10n.tr("Localizable", "everyInterval", String(describing: p1), fallback: "Every %1$@")
  }
  /// Executed
  internal static let executed = L10n.tr("Localizable", "executed", fallback: "Executed")
  /// Existing items
  internal static let existingItems = L10n.tr("Localizable", "existingItems", fallback: "Existing items")
  /// This item exists on your Jellyfin Server.
  internal static let existsOnServer = L10n.tr("Localizable", "existsOnServer", fallback: "This item exists on your Jellyfin Server.")
  /// Experimental
  internal static let experimental = L10n.tr("Localizable", "experimental", fallback: "Experimental")
  /// External
  internal static let external = L10n.tr("Localizable", "external", fallback: "External")
  /// Failed to delete item at index %1$@: %2$@
  internal static func failedDeletionAtIndexError(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "failedDeletionAtIndexError", String(describing: p1), String(describing: p2), fallback: "Failed to delete item at index %1$@: %2$@")
  }
  /// Failed logins
  internal static let failedLogins = L10n.tr("Localizable", "failedLogins", fallback: "Failed logins")
  /// Favorite
  internal static let favorite = L10n.tr("Localizable", "favorite", fallback: "Favorite")
  /// Favorited
  internal static let favorited = L10n.tr("Localizable", "favorited", fallback: "Favorited")
  /// Favorites
  internal static let favorites = L10n.tr("Localizable", "favorites", fallback: "Favorites")
  /// Featurette
  internal static let featurette = L10n.tr("Localizable", "featurette", fallback: "Featurette")
  /// File
  internal static let file = L10n.tr("Localizable", "file", fallback: "File")
  /// Filters
  internal static let filters = L10n.tr("Localizable", "filters", fallback: "Filters")
  /// Find missing
  internal static let findMissing = L10n.tr("Localizable", "findMissing", fallback: "Find missing")
  /// Find missing metadata and images.
  internal static let findMissingDescription = L10n.tr("Localizable", "findMissingDescription", fallback: "Find missing metadata and images.")
  /// Folder
  internal static let folder = L10n.tr("Localizable", "folder", fallback: "Folder")
  /// Folders
  internal static let folders = L10n.tr("Localizable", "folders", fallback: "Folders")
  /// Forced
  internal static let forced = L10n.tr("Localizable", "forced", fallback: "Forced")
  /// Force remote media transcoding
  internal static let forceRemoteTranscoding = L10n.tr("Localizable", "forceRemoteTranscoding", fallback: "Force remote media transcoding")
  /// Format
  internal static let format = L10n.tr("Localizable", "format", fallback: "Format")
  /// 3D format
  internal static let format3D = L10n.tr("Localizable", "format3D", fallback: "3D format")
  /// Full side-by-side
  internal static let fullSideBySide = L10n.tr("Localizable", "fullSideBySide", fallback: "Full side-by-side")
  /// Full top and bottom
  internal static let fullTopAndBottom = L10n.tr("Localizable", "fullTopAndBottom", fallback: "Full top and bottom")
  /// Genre
  internal static let genre = L10n.tr("Localizable", "genre", fallback: "Genre")
  /// Genres
  internal static let genres = L10n.tr("Localizable", "genres", fallback: "Genres")
  /// Categories that describe the themes or styles of media.
  internal static let genresDescription = L10n.tr("Localizable", "genresDescription", fallback: "Categories that describe the themes or styles of media.")
  /// Gesture lock
  internal static let gestureLock = L10n.tr("Localizable", "gestureLock", fallback: "Gesture lock")
  /// Gestures
  internal static let gestures = L10n.tr("Localizable", "gestures", fallback: "Gestures")
  /// Gestures locked
  internal static let gesturesLocked = L10n.tr("Localizable", "gesturesLocked", fallback: "Gestures locked")
  /// Gestures unlocked
  internal static let gesturesUnlocked = L10n.tr("Localizable", "gesturesUnlocked", fallback: "Gestures unlocked")
  /// Gbps
  internal static let gigabitsPerSecond = L10n.tr("Localizable", "gigabitsPerSecond", fallback: "Gbps")
  /// Green
  internal static let green = L10n.tr("Localizable", "green", fallback: "Green")
  /// Grid
  internal static let grid = L10n.tr("Localizable", "grid", fallback: "Grid")
  /// Guest star
  internal static let guestStar = L10n.tr("Localizable", "guestStar", fallback: "Guest star")
  /// Half side-by-side
  internal static let halfSideBySide = L10n.tr("Localizable", "halfSideBySide", fallback: "Half side-by-side")
  /// Half top and bottom
  internal static let halfTopAndBottom = L10n.tr("Localizable", "halfTopAndBottom", fallback: "Half top and bottom")
  /// Hearing impaired
  internal static let hearingImpaired = L10n.tr("Localizable", "hearingImpaired", fallback: "Hearing impaired")
  /// Hidden
  internal static let hidden = L10n.tr("Localizable", "hidden", fallback: "Hidden")
  /// Hide user from login screen
  internal static let hideUserFromLoginScreen = L10n.tr("Localizable", "hideUserFromLoginScreen", fallback: "Hide user from login screen")
  /// Hint
  internal static let hint = L10n.tr("Localizable", "hint", fallback: "Hint")
  /// Home
  internal static let home = L10n.tr("Localizable", "home", fallback: "Home")
  /// Horizontal pan
  internal static let horizontalPan = L10n.tr("Localizable", "horizontalPan", fallback: "Horizontal pan")
  /// Horizontal swipe
  internal static let horizontalSwipe = L10n.tr("Localizable", "horizontalSwipe", fallback: "Horizontal swipe")
  /// Hours
  internal static let hours = L10n.tr("Localizable", "hours", fallback: "Hours")
  /// ID
  internal static let id = L10n.tr("Localizable", "id", fallback: "ID")
  /// Identify
  internal static let identify = L10n.tr("Localizable", "identify", fallback: "Identify")
  /// Idle
  internal static let idle = L10n.tr("Localizable", "idle", fallback: "Idle")
  /// Illustrator
  internal static let illustrator = L10n.tr("Localizable", "illustrator", fallback: "Illustrator")
  /// Images
  internal static let image = L10n.tr("Localizable", "image", fallback: "Images")
  /// Images
  internal static let images = L10n.tr("Localizable", "images", fallback: "Images")
  /// Image source
  internal static let imageSource = L10n.tr("Localizable", "imageSource", fallback: "Image source")
  /// Inactive
  internal static let inactive = L10n.tr("Localizable", "inactive", fallback: "Inactive")
  /// Incorrect pin for %@
  internal static func incorrectPinForUser(_ p1: Any) -> String {
    return L10n.tr("Localizable", "incorrectPinForUser", String(describing: p1), fallback: "Incorrect pin for %@")
  }
  /// Index
  internal static let index = L10n.tr("Localizable", "index", fallback: "Index")
  /// Index number
  internal static let indexNumber = L10n.tr("Localizable", "indexNumber", fallback: "Index number")
  /// Indicators
  internal static let indicators = L10n.tr("Localizable", "indicators", fallback: "Indicators")
  /// Inker
  internal static let inker = L10n.tr("Localizable", "inker", fallback: "Inker")
  /// Interlaced video is not supported
  internal static let interlacedVideoNotSupported = L10n.tr("Localizable", "interlacedVideoNotSupported", fallback: "Interlaced video is not supported")
  /// Interval
  internal static let interval = L10n.tr("Localizable", "interval", fallback: "Interval")
  /// Interview
  internal static let interview = L10n.tr("Localizable", "interview", fallback: "Interview")
  /// Invalid format
  internal static let invalidFormat = L10n.tr("Localizable", "invalidFormat", fallback: "Invalid format")
  /// Inverted dark
  internal static let invertedDark = L10n.tr("Localizable", "invertedDark", fallback: "Inverted dark")
  /// Inverted light
  internal static let invertedLight = L10n.tr("Localizable", "invertedLight", fallback: "Inverted light")
  /// %1$@ at %2$@
  internal static func itemAtItem(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "itemAtItem", String(describing: p1), String(describing: p2), fallback: "%1$@ at %2$@")
  }
  /// Items
  internal static let items = L10n.tr("Localizable", "items", fallback: "Items")
  /// Jellyfin
  internal static let jellyfin = L10n.tr("Localizable", "jellyfin", fallback: "Jellyfin")
  /// Join groups
  internal static let joinGroups = L10n.tr("Localizable", "joinGroups", fallback: "Join groups")
  /// Jump
  internal static let jump = L10n.tr("Localizable", "jump", fallback: "Jump")
  /// Jump backward
  internal static let jumpBackward = L10n.tr("Localizable", "jumpBackward", fallback: "Jump backward")
  /// Jump backward length
  internal static let jumpBackwardLength = L10n.tr("Localizable", "jumpBackwardLength", fallback: "Jump backward length")
  /// Jump forward
  internal static let jumpForward = L10n.tr("Localizable", "jumpForward", fallback: "Jump forward")
  /// Jump forward length
  internal static let jumpForwardLength = L10n.tr("Localizable", "jumpForwardLength", fallback: "Jump forward length")
  /// Kids
  internal static let kids = L10n.tr("Localizable", "kids", fallback: "Kids")
  /// kbps
  internal static let kilobitsPerSecond = L10n.tr("Localizable", "kilobitsPerSecond", fallback: "kbps")
  /// Landscape
  internal static let landscape = L10n.tr("Localizable", "landscape", fallback: "Landscape")
  /// Language
  internal static let language = L10n.tr("Localizable", "language", fallback: "Language")
  /// Large
  internal static let large = L10n.tr("Localizable", "large", fallback: "Large")
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
  /// Last seen
  internal static let lastSeen = L10n.tr("Localizable", "lastSeen", fallback: "Last seen")
  /// Latest %@
  internal static func latestWithString(_ p1: Any) -> String {
    return L10n.tr("Localizable", "latestWithString", String(describing: p1), fallback: "Latest %@")
  }
  /// Layout
  internal static let layout = L10n.tr("Localizable", "layout", fallback: "Layout")
  /// Learn more
  internal static let learnMore = L10n.tr("Localizable", "learnMore", fallback: "Learn more")
  /// Left
  internal static let `left` = L10n.tr("Localizable", "left", fallback: "Left")
  /// Left vertical pan
  internal static let leftVerticalPan = L10n.tr("Localizable", "leftVerticalPan", fallback: "Left vertical pan")
  /// Letter
  internal static let letter = L10n.tr("Localizable", "letter", fallback: "Letter")
  /// Letterer
  internal static let letterer = L10n.tr("Localizable", "letterer", fallback: "Letterer")
  /// Letter picker
  internal static let letterPicker = L10n.tr("Localizable", "letterPicker", fallback: "Letter picker")
  /// Level
  internal static let level = L10n.tr("Localizable", "level", fallback: "Level")
  /// Libraries
  internal static let libraries = L10n.tr("Localizable", "libraries", fallback: "Libraries")
  /// Library
  internal static let library = L10n.tr("Localizable", "library", fallback: "Library")
  /// Light
  internal static let light = L10n.tr("Localizable", "light", fallback: "Light")
  /// Liked items
  internal static let likedItems = L10n.tr("Localizable", "likedItems", fallback: "Liked items")
  /// Likes
  internal static let likes = L10n.tr("Localizable", "likes", fallback: "Likes")
  /// List
  internal static let list = L10n.tr("Localizable", "list", fallback: "List")
  /// Live TV
  internal static let liveTV = L10n.tr("Localizable", "liveTV", fallback: "Live TV")
  /// Live TV access
  internal static let liveTVAccess = L10n.tr("Localizable", "liveTVAccess", fallback: "Live TV access")
  /// Live TV Access
  internal static let liveTVAccessCapitalized = L10n.tr("Localizable", "liveTVAccessCapitalized", fallback: "Live TV Access")
  /// Live TV channel
  internal static let liveTVChannel = L10n.tr("Localizable", "liveTVChannel", fallback: "Live TV channel")
  /// Live TV channels
  internal static let liveTVChannels = L10n.tr("Localizable", "liveTVChannels", fallback: "Live TV channels")
  /// Live TV program
  internal static let liveTVProgram = L10n.tr("Localizable", "liveTVProgram", fallback: "Live TV program")
  /// Live TV programs
  internal static let liveTVPrograms = L10n.tr("Localizable", "liveTVPrograms", fallback: "Live TV programs")
  /// Live TV recording management
  internal static let liveTVRecordingManagement = L10n.tr("Localizable", "liveTVRecordingManagement", fallback: "Live TV recording management")
  /// Loading user failed
  internal static let loadingUserFailed = L10n.tr("Localizable", "loadingUserFailed", fallback: "Loading user failed")
  /// Local
  internal static let local = L10n.tr("Localizable", "local", fallback: "Local")
  /// Local servers
  internal static let localServers = L10n.tr("Localizable", "localServers", fallback: "Local servers")
  /// Lock all fields
  internal static let lockAllFields = L10n.tr("Localizable", "lockAllFields", fallback: "Lock all fields")
  /// Locked fields
  internal static let lockedFields = L10n.tr("Localizable", "lockedFields", fallback: "Locked fields")
  /// Locked users
  internal static let lockedUsers = L10n.tr("Localizable", "lockedUsers", fallback: "Locked users")
  /// Logo
  internal static let logo = L10n.tr("Localizable", "logo", fallback: "Logo")
  /// Logs
  internal static let logs = L10n.tr("Localizable", "logs", fallback: "Logs")
  /// Access the Jellyfin server logs for troubleshooting and monitoring purposes.
  internal static let logsDescription = L10n.tr("Localizable", "logsDescription", fallback: "Access the Jellyfin server logs for troubleshooting and monitoring purposes.")
  /// Long press
  internal static let longPress = L10n.tr("Localizable", "longPress", fallback: "Long press")
  /// Lyricist
  internal static let lyricist = L10n.tr("Localizable", "lyricist", fallback: "Lyricist")
  /// Lyrics
  internal static let lyrics = L10n.tr("Localizable", "lyrics", fallback: "Lyrics")
  /// Manage
  internal static let manage = L10n.tr("Localizable", "manage", fallback: "Manage")
  /// Management
  internal static let management = L10n.tr("Localizable", "management", fallback: "Management")
  /// Delete, upload, or search for external subtitles.
  internal static let manageSubtitlesDescription = L10n.tr("Localizable", "manageSubtitlesDescription", fallback: "Delete, upload, or search for external subtitles.")
  /// Manual playlists folder
  internal static let manualPlaylistsFolder = L10n.tr("Localizable", "manualPlaylistsFolder", fallback: "Manual playlists folder")
  /// Manual playlists folders
  internal static let manualPlaylistsFolders = L10n.tr("Localizable", "manualPlaylistsFolders", fallback: "Manual playlists folders")
  /// Maximum bitrate
  internal static let maximumBitrate = L10n.tr("Localizable", "maximumBitrate", fallback: "Maximum bitrate")
  /// Limits the total number of connections a user can have to the server.
  internal static let maximumConnectionsDescription = L10n.tr("Localizable", "maximumConnectionsDescription", fallback: "Limits the total number of connections a user can have to the server.")
  /// Maximum failed login policy
  internal static let maximumFailedLoginPolicy = L10n.tr("Localizable", "maximumFailedLoginPolicy", fallback: "Maximum failed login policy")
  /// Sets the maximum failed login attempts before a user is locked out.
  internal static let maximumFailedLoginPolicyDescription = L10n.tr("Localizable", "maximumFailedLoginPolicyDescription", fallback: "Sets the maximum failed login attempts before a user is locked out.")
  /// Locked users must be re-enabled by an Administrator.
  internal static let maximumFailedLoginPolicyReenable = L10n.tr("Localizable", "maximumFailedLoginPolicyReenable", fallback: "Locked users must be re-enabled by an Administrator.")
  /// Maximum remote bitrate
  internal static let maximumRemoteBitrate = L10n.tr("Localizable", "maximumRemoteBitrate", fallback: "Maximum remote bitrate")
  /// Maximum sessions
  internal static let maximumSessions = L10n.tr("Localizable", "maximumSessions", fallback: "Maximum sessions")
  /// Maximum sessions policy
  internal static let maximumSessionsPolicy = L10n.tr("Localizable", "maximumSessionsPolicy", fallback: "Maximum sessions policy")
  /// Maximum parental rating
  internal static let maxParentalRating = L10n.tr("Localizable", "maxParentalRating", fallback: "Maximum parental rating")
  /// Content with a higher rating will be hidden from this user.
  internal static let maxParentalRatingDescription = L10n.tr("Localizable", "maxParentalRatingDescription", fallback: "Content with a higher rating will be hidden from this user.")
  /// Media
  internal static let media = L10n.tr("Localizable", "media", fallback: "Media")
  /// Media access
  internal static let mediaAccess = L10n.tr("Localizable", "mediaAccess", fallback: "Media access")
  /// Media attributes
  internal static let mediaAttributes = L10n.tr("Localizable", "mediaAttributes", fallback: "Media attributes")
  /// Media downloads
  internal static let mediaDownloads = L10n.tr("Localizable", "mediaDownloads", fallback: "Media downloads")
  /// Media playback
  internal static let mediaPlayback = L10n.tr("Localizable", "mediaPlayback", fallback: "Media playback")
  /// Mbps
  internal static let megabitsPerSecond = L10n.tr("Localizable", "megabitsPerSecond", fallback: "Mbps")
  /// Menu
  internal static let menu = L10n.tr("Localizable", "menu", fallback: "Menu")
  /// Menu buttons
  internal static let menuButtons = L10n.tr("Localizable", "menuButtons", fallback: "Menu buttons")
  /// Metadata
  internal static let metadata = L10n.tr("Localizable", "metadata", fallback: "Metadata")
  /// Metadata preferences
  internal static let metadataPreferences = L10n.tr("Localizable", "metadataPreferences", fallback: "Metadata preferences")
  /// Method
  internal static let method = L10n.tr("Localizable", "method", fallback: "Method")
  /// Minutes
  internal static let minutes = L10n.tr("Localizable", "minutes", fallback: "Minutes")
  /// Missing
  internal static let missing = L10n.tr("Localizable", "missing", fallback: "Missing")
  /// Missing codec values
  internal static let missingCodecValues = L10n.tr("Localizable", "missingCodecValues", fallback: "Missing codec values")
  /// Missing items
  internal static let missingItems = L10n.tr("Localizable", "missingItems", fallback: "Missing items")
  /// Mixer
  internal static let mixer = L10n.tr("Localizable", "mixer", fallback: "Mixer")
  /// Movie
  internal static let movie = L10n.tr("Localizable", "movie", fallback: "Movie")
  /// Movies
  internal static let movies = L10n.tr("Localizable", "movies", fallback: "Movies")
  /// Multi tap
  internal static let multiTap = L10n.tr("Localizable", "multiTap", fallback: "Multi tap")
  /// Music
  internal static let music = L10n.tr("Localizable", "music", fallback: "Music")
  /// Music video
  internal static let musicVideo = L10n.tr("Localizable", "musicVideo", fallback: "Music video")
  /// Music videos
  internal static let musicVideos = L10n.tr("Localizable", "musicVideos", fallback: "Music videos")
  /// MVC
  internal static let mvc = L10n.tr("Localizable", "mvc", fallback: "MVC")
  /// Name
  internal static let name = L10n.tr("Localizable", "name", fallback: "Name")
  /// Native
  internal static let native = L10n.tr("Localizable", "native", fallback: "Native")
  /// Native Player
  internal static let nativePlayer = L10n.tr("Localizable", "nativePlayer", fallback: "Native Player")
  /// Network timed out
  internal static let networkTimedOut = L10n.tr("Localizable", "networkTimedOut", fallback: "Network timed out")
  /// Never
  internal static let never = L10n.tr("Localizable", "never", fallback: "Never")
  /// Never run
  internal static let neverRun = L10n.tr("Localizable", "neverRun", fallback: "Never run")
  /// New password
  internal static let newPassword = L10n.tr("Localizable", "newPassword", fallback: "New password")
  /// News
  internal static let news = L10n.tr("Localizable", "news", fallback: "News")
  /// New user
  internal static let newUser = L10n.tr("Localizable", "newUser", fallback: "New user")
  /// Next
  internal static let next = L10n.tr("Localizable", "next", fallback: "Next")
  /// Next item
  internal static let nextItem = L10n.tr("Localizable", "nextItem", fallback: "Next item")
  /// Next Up
  internal static let nextUp = L10n.tr("Localizable", "nextUp", fallback: "Next Up")
  /// Days in Next Up
  internal static let nextUpDays = L10n.tr("Localizable", "nextUpDays", fallback: "Days in Next Up")
  /// Set the maximum amount of days a show should stay in the 'Next Up' list without watching it.
  internal static let nextUpDaysDescription = L10n.tr("Localizable", "nextUpDaysDescription", fallback: "Set the maximum amount of days a show should stay in the 'Next Up' list without watching it.")
  /// Rewatching in Next Up
  internal static let nextUpRewatch = L10n.tr("Localizable", "nextUpRewatch", fallback: "Rewatching in Next Up")
  /// No
  internal static let no = L10n.tr("Localizable", "no", fallback: "No")
  /// No profiles defined. Playback issues may occur.
  internal static let noDeviceProfileWarning = L10n.tr("Localizable", "noDeviceProfileWarning", fallback: "No profiles defined. Playback issues may occur.")
  /// No episodes available
  internal static let noEpisodesAvailable = L10n.tr("Localizable", "noEpisodesAvailable", fallback: "No episodes available")
  /// No item selected
  internal static let noItemSelected = L10n.tr("Localizable", "noItemSelected", fallback: "No item selected")
  /// No local servers found
  internal static let noLocalServersFound = L10n.tr("Localizable", "noLocalServersFound", fallback: "No local servers found")
  /// None
  internal static let `none` = L10n.tr("Localizable", "none", fallback: "None")
  /// No overview available
  internal static let noOverviewAvailable = L10n.tr("Localizable", "noOverviewAvailable", fallback: "No overview available")
  /// No public users
  internal static let noPublicUsers = L10n.tr("Localizable", "noPublicUsers", fallback: "No public users")
  /// No results.
  internal static let noResults = L10n.tr("Localizable", "noResults", fallback: "No results.")
  /// Normal
  internal static let normal = L10n.tr("Localizable", "normal", fallback: "Normal")
  /// No runtime limit
  internal static let noRuntimeLimit = L10n.tr("Localizable", "noRuntimeLimit", fallback: "No runtime limit")
  /// No session
  internal static let noSession = L10n.tr("Localizable", "noSession", fallback: "No session")
  /// Type: %@ not implemented yet :(
  internal static func notImplementedYetWithType(_ p1: Any) -> String {
    return L10n.tr("Localizable", "notImplementedYetWithType", String(describing: p1), fallback: "Type: %@ not implemented yet :(")
  }
  /// Official rating
  internal static let officialRating = L10n.tr("Localizable", "officialRating", fallback: "Official rating")
  /// Offset
  internal static let offset = L10n.tr("Localizable", "offset", fallback: "Offset")
  /// OK
  internal static let ok = L10n.tr("Localizable", "ok", fallback: "OK")
  /// On application startup
  internal static let onApplicationStartup = L10n.tr("Localizable", "onApplicationStartup", fallback: "On application startup")
  /// On Now
  internal static let onNow = L10n.tr("Localizable", "onNow", fallback: "On Now")
  /// Options
  internal static let options = L10n.tr("Localizable", "options", fallback: "Options")
  /// Orange
  internal static let orange = L10n.tr("Localizable", "orange", fallback: "Orange")
  /// Order
  internal static let order = L10n.tr("Localizable", "order", fallback: "Order")
  /// Orientation
  internal static let orientation = L10n.tr("Localizable", "orientation", fallback: "Orientation")
  /// Original air date
  internal static let originalAirDate = L10n.tr("Localizable", "originalAirDate", fallback: "Original air date")
  /// Original aspect ratio
  internal static let originalAspectRatio = L10n.tr("Localizable", "originalAspectRatio", fallback: "Original aspect ratio")
  /// Original title
  internal static let originalTitle = L10n.tr("Localizable", "originalTitle", fallback: "Original title")
  /// Other
  internal static let other = L10n.tr("Localizable", "other", fallback: "Other")
  /// Out of date
  internal static let outOfDate = L10n.tr("Localizable", "outOfDate", fallback: "Out of date")
  /// Overview
  internal static let overview = L10n.tr("Localizable", "overview", fallback: "Overview")
  /// Parental controls
  internal static let parentalControls = L10n.tr("Localizable", "parentalControls", fallback: "Parental controls")
  /// Parental rating
  internal static let parentalRating = L10n.tr("Localizable", "parentalRating", fallback: "Parental rating")
  /// Parental ratings
  internal static let parentalRatings = L10n.tr("Localizable", "parentalRatings", fallback: "Parental ratings")
  /// Parent index
  internal static let parentIndexNumber = L10n.tr("Localizable", "parentIndexNumber", fallback: "Parent index")
  /// Password
  internal static let password = L10n.tr("Localizable", "password", fallback: "Password")
  /// User password has been changed.
  internal static let passwordChangedMessage = L10n.tr("Localizable", "passwordChangedMessage", fallback: "User password has been changed.")
  /// Changes the Jellyfin server user password. This does not change any Swiftfin settings.
  internal static let passwordChangeWarning = L10n.tr("Localizable", "passwordChangeWarning", fallback: "Changes the Jellyfin server user password. This does not change any Swiftfin settings.")
  /// New passwords do not match.
  internal static let passwordsDoNotMatch = L10n.tr("Localizable", "passwordsDoNotMatch", fallback: "New passwords do not match.")
  /// Pause
  internal static let pause = L10n.tr("Localizable", "pause", fallback: "Pause")
  /// Penciller
  internal static let penciller = L10n.tr("Localizable", "penciller", fallback: "Penciller")
  /// People
  internal static let people = L10n.tr("Localizable", "people", fallback: "People")
  /// People who helped create or perform specific media.
  internal static let peopleDescription = L10n.tr("Localizable", "peopleDescription", fallback: "People who helped create or perform specific media.")
  /// Perfect match
  internal static let perfectMatch = L10n.tr("Localizable", "perfectMatch", fallback: "Perfect match")
  /// Permissions
  internal static let permissions = L10n.tr("Localizable", "permissions", fallback: "Permissions")
  /// Person
  internal static let person = L10n.tr("Localizable", "person", fallback: "Person")
  /// Photo
  internal static let photo = L10n.tr("Localizable", "photo", fallback: "Photo")
  /// Photo album
  internal static let photoAlbum = L10n.tr("Localizable", "photoAlbum", fallback: "Photo album")
  /// Photo albums
  internal static let photoAlbums = L10n.tr("Localizable", "photoAlbums", fallback: "Photo albums")
  /// Photos
  internal static let photos = L10n.tr("Localizable", "photos", fallback: "Photos")
  /// Pin
  internal static let pin = L10n.tr("Localizable", "pin", fallback: "Pin")
  /// Pinch
  internal static let pinch = L10n.tr("Localizable", "pinch", fallback: "Pinch")
  /// Play
  internal static let play = L10n.tr("Localizable", "play", fallback: "Play")
  /// Play / Pause
  internal static let playAndPause = L10n.tr("Localizable", "playAndPause", fallback: "Play / Pause")
  /// Playback quality
  internal static let playbackQuality = L10n.tr("Localizable", "playbackQuality", fallback: "Playback quality")
  /// Playback speed
  internal static let playbackSpeed = L10n.tr("Localizable", "playbackSpeed", fallback: "Playback speed")
  /// Play count
  internal static let playCount = L10n.tr("Localizable", "playCount", fallback: "Play count")
  /// Played
  internal static let played = L10n.tr("Localizable", "played", fallback: "Played")
  /// Play From beginning
  internal static let playFromBeginning = L10n.tr("Localizable", "playFromBeginning", fallback: "Play From beginning")
  /// Playlist
  internal static let playlist = L10n.tr("Localizable", "playlist", fallback: "Playlist")
  /// Playlists
  internal static let playlists = L10n.tr("Localizable", "playlists", fallback: "Playlists")
  /// Playlists folder
  internal static let playlistsFolder = L10n.tr("Localizable", "playlistsFolder", fallback: "Playlists folder")
  /// Playlists folders
  internal static let playlistsFolders = L10n.tr("Localizable", "playlistsFolders", fallback: "Playlists folders")
  /// Play next item
  internal static let playNextItem = L10n.tr("Localizable", "playNextItem", fallback: "Play next item")
  /// Play previous item
  internal static let playPreviousItem = L10n.tr("Localizable", "playPreviousItem", fallback: "Play previous item")
  /// Portrait
  internal static let portrait = L10n.tr("Localizable", "portrait", fallback: "Portrait")
  /// Posters
  internal static let posters = L10n.tr("Localizable", "posters", fallback: "Posters")
  /// Premiere date
  internal static let premiereDate = L10n.tr("Localizable", "premiereDate", fallback: "Premiere date")
  /// Preview image
  internal static let previewImage = L10n.tr("Localizable", "previewImage", fallback: "Preview image")
  /// Previous item
  internal static let previousItem = L10n.tr("Localizable", "previousItem", fallback: "Previous item")
  /// Primary
  internal static let primary = L10n.tr("Localizable", "primary", fallback: "Primary")
  /// Producer
  internal static let producer = L10n.tr("Localizable", "producer", fallback: "Producer")
  /// Production
  internal static let production = L10n.tr("Localizable", "production", fallback: "Production")
  /// Production locations
  internal static let productionLocations = L10n.tr("Localizable", "productionLocations", fallback: "Production locations")
  /// Production year
  internal static let productionYear = L10n.tr("Localizable", "productionYear", fallback: "Production year")
  /// Profile
  internal static let profile = L10n.tr("Localizable", "profile", fallback: "Profile")
  /// Profile image
  internal static let profileImage = L10n.tr("Localizable", "profileImage", fallback: "Profile image")
  /// Profile not saved
  internal static let profileNotSaved = L10n.tr("Localizable", "profileNotSaved", fallback: "Profile not saved")
  /// Profiles
  internal static let profiles = L10n.tr("Localizable", "profiles", fallback: "Profiles")
  /// Program
  internal static let program = L10n.tr("Localizable", "program", fallback: "Program")
  /// Programs
  internal static let programs = L10n.tr("Localizable", "programs", fallback: "Programs")
  /// Progress
  internal static let progress = L10n.tr("Localizable", "progress", fallback: "Progress")
  /// Provider
  internal static let provider = L10n.tr("Localizable", "provider", fallback: "Provider")
  /// Public users
  internal static let publicUsers = L10n.tr("Localizable", "publicUsers", fallback: "Public users")
  /// Quick Connect
  internal static let quickConnect = L10n.tr("Localizable", "quickConnect", fallback: "Quick Connect")
  /// Quick Connect code
  internal static let quickConnectCode = L10n.tr("Localizable", "quickConnectCode", fallback: "Quick Connect code")
  /// Enter the 6 digit code from your other device.
  internal static let quickConnectCodeInstruction = L10n.tr("Localizable", "quickConnectCodeInstruction", fallback: "Enter the 6 digit code from your other device.")
  /// Open the Jellyfin app on your phone or web browser and sign in with your account
  internal static let quickConnectStep1 = L10n.tr("Localizable", "quickConnectStep1", fallback: "Open the Jellyfin app on your phone or web browser and sign in with your account")
  /// Open the user menu and go to the Quick Connect page
  internal static let quickConnectStep2 = L10n.tr("Localizable", "quickConnectStep2", fallback: "Open the user menu and go to the Quick Connect page")
  /// Enter the following code:
  internal static let quickConnectStep3 = L10n.tr("Localizable", "quickConnectStep3", fallback: "Enter the following code:")
  /// Authorizing Quick Connect successful. Please continue on your other device.
  internal static let quickConnectSuccessMessage = L10n.tr("Localizable", "quickConnectSuccessMessage", fallback: "Authorizing Quick Connect successful. Please continue on your other device.")
  /// This user will be authenticated to the other device.
  internal static let quickConnectUserDisclaimer = L10n.tr("Localizable", "quickConnectUserDisclaimer", fallback: "This user will be authenticated to the other device.")
  /// Random
  internal static let random = L10n.tr("Localizable", "random", fallback: "Random")
  /// Random image
  internal static let randomImage = L10n.tr("Localizable", "randomImage", fallback: "Random image")
  /// Rating
  internal static let rating = L10n.tr("Localizable", "rating", fallback: "Rating")
  /// Ratings
  internal static let ratings = L10n.tr("Localizable", "ratings", fallback: "Ratings")
  /// Recently Added
  internal static let recentlyAdded = L10n.tr("Localizable", "recentlyAdded", fallback: "Recently Added")
  /// Recommended
  internal static let recommended = L10n.tr("Localizable", "recommended", fallback: "Recommended")
  /// Recording
  internal static let recording = L10n.tr("Localizable", "recording", fallback: "Recording")
  /// Recordings
  internal static let recordings = L10n.tr("Localizable", "recordings", fallback: "Recordings")
  /// Red
  internal static let red = L10n.tr("Localizable", "red", fallback: "Red")
  /// The number of reference frames is not supported
  internal static let refFramesNotSupported = L10n.tr("Localizable", "refFramesNotSupported", fallback: "The number of reference frames is not supported")
  /// Refresh metadata
  internal static let refreshMetadata = L10n.tr("Localizable", "refreshMetadata", fallback: "Refresh metadata")
  /// Regional
  internal static let regional = L10n.tr("Localizable", "regional", fallback: "Regional")
  /// Regular
  internal static let regular = L10n.tr("Localizable", "regular", fallback: "Regular")
  /// Release date
  internal static let releaseDate = L10n.tr("Localizable", "releaseDate", fallback: "Release date")
  /// Remember layout
  internal static let rememberLayout = L10n.tr("Localizable", "rememberLayout", fallback: "Remember layout")
  /// Remember layout for individual libraries.
  internal static let rememberLayoutFooter = L10n.tr("Localizable", "rememberLayoutFooter", fallback: "Remember layout for individual libraries.")
  /// Remember sorting
  internal static let rememberSorting = L10n.tr("Localizable", "rememberSorting", fallback: "Remember sorting")
  /// Remember sorting for individual libraries.
  internal static let rememberSortingFooter = L10n.tr("Localizable", "rememberSortingFooter", fallback: "Remember sorting for individual libraries.")
  /// Remixer
  internal static let remixer = L10n.tr("Localizable", "remixer", fallback: "Remixer")
  /// Remote connections
  internal static let remoteConnections = L10n.tr("Localizable", "remoteConnections", fallback: "Remote connections")
  /// Remote control
  internal static let remoteControl = L10n.tr("Localizable", "remoteControl", fallback: "Remote control")
  /// Remove all
  internal static let removeAll = L10n.tr("Localizable", "removeAll", fallback: "Remove all")
  /// Remux
  internal static let remux = L10n.tr("Localizable", "remux", fallback: "Remux")
  /// Reorder
  internal static let reorder = L10n.tr("Localizable", "reorder", fallback: "Reorder")
  /// Replace
  internal static let replace = L10n.tr("Localizable", "replace", fallback: "Replace")
  /// Replace all
  internal static let replaceAll = L10n.tr("Localizable", "replaceAll", fallback: "Replace all")
  /// Replace all unlocked metadata and images with new information.
  internal static let replaceAllDescription = L10n.tr("Localizable", "replaceAllDescription", fallback: "Replace all unlocked metadata and images with new information.")
  /// Current profile values may cause playback issues
  internal static let replaceDeviceProfileWarning = L10n.tr("Localizable", "replaceDeviceProfileWarning", fallback: "Current profile values may cause playback issues")
  /// Replace images
  internal static let replaceImages = L10n.tr("Localizable", "replaceImages", fallback: "Replace images")
  /// Replace all images with new images.
  internal static let replaceImagesDescription = L10n.tr("Localizable", "replaceImagesDescription", fallback: "Replace all images with new images.")
  /// Are you sure you want to replace this item?
  internal static let replaceItemConfirmation = L10n.tr("Localizable", "replaceItemConfirmation", fallback: "Are you sure you want to replace this item?")
  /// Replace metadata
  internal static let replaceMetadata = L10n.tr("Localizable", "replaceMetadata", fallback: "Replace metadata")
  /// Replace unlocked metadata with new information.
  internal static let replaceMetadataDescription = L10n.tr("Localizable", "replaceMetadataDescription", fallback: "Replace unlocked metadata with new information.")
  /// Replace subtitle
  internal static let replaceSubtitle = L10n.tr("Localizable", "replaceSubtitle", fallback: "Replace subtitle")
  /// Required
  internal static let `required` = L10n.tr("Localizable", "required", fallback: "Required")
  /// Require device authentication when signing in to the user.
  internal static let requireDeviceAuthDescription = L10n.tr("Localizable", "requireDeviceAuthDescription", fallback: "Require device authentication when signing in to the user.")
  /// Require device authentication to sign in to %@ on this device.
  internal static func requireDeviceAuthForUser(_ p1: Any) -> String {
    return L10n.tr("Localizable", "requireDeviceAuthForUser", String(describing: p1), fallback: "Require device authentication to sign in to %@ on this device.")
  }
  /// Require a local pin when signing in to the user. This pin is unrecoverable.
  internal static let requirePinDescription = L10n.tr("Localizable", "requirePinDescription", fallback: "Require a local pin when signing in to the user. This pin is unrecoverable.")
  /// Reset
  internal static let reset = L10n.tr("Localizable", "reset", fallback: "Reset")
  /// Reset the filter values to none.
  internal static let resetFilterFooter = L10n.tr("Localizable", "resetFilterFooter", fallback: "Reset the filter values to none.")
  /// Reset settings
  internal static let resetSettings = L10n.tr("Localizable", "resetSettings", fallback: "Reset settings")
  /// Reset Swiftfin user settings.
  internal static let resetSettingsDescription = L10n.tr("Localizable", "resetSettingsDescription", fallback: "Reset Swiftfin user settings.")
  /// Are you sure you want to reset all user settings?
  internal static let resetSettingsMessage = L10n.tr("Localizable", "resetSettingsMessage", fallback: "Are you sure you want to reset all user settings?")
  /// Restart server
  internal static let restartServer = L10n.tr("Localizable", "restartServer", fallback: "Restart server")
  /// Are you sure you want to restart the server?
  internal static let restartWarning = L10n.tr("Localizable", "restartWarning", fallback: "Are you sure you want to restart the server?")
  /// Resume
  internal static let resume = L10n.tr("Localizable", "resume", fallback: "Resume")
  /// Resume offset
  internal static let resumeOffset = L10n.tr("Localizable", "resumeOffset", fallback: "Resume offset")
  /// Resume content seconds before the recorded resume time.
  internal static let resumeOffsetDescription = L10n.tr("Localizable", "resumeOffsetDescription", fallback: "Resume content seconds before the recorded resume time.")
  /// Resume Offset
  internal static let resumeOffsetTitle = L10n.tr("Localizable", "resumeOffsetTitle", fallback: "Resume Offset")
  /// Retrieving media information
  internal static let retrievingMediaInformation = L10n.tr("Localizable", "retrievingMediaInformation", fallback: "Retrieving media information")
  /// Retry
  internal static let retry = L10n.tr("Localizable", "retry", fallback: "Retry")
  /// Reviews
  internal static let reviews = L10n.tr("Localizable", "reviews", fallback: "Reviews")
  /// Right
  internal static let `right` = L10n.tr("Localizable", "right", fallback: "Right")
  /// Right vertical pan
  internal static let rightVerticalPan = L10n.tr("Localizable", "rightVerticalPan", fallback: "Right vertical pan")
  /// Role
  internal static let role = L10n.tr("Localizable", "role", fallback: "Role")
  /// Rotate
  internal static let rotate = L10n.tr("Localizable", "rotate", fallback: "Rotate")
  /// Run
  internal static let run = L10n.tr("Localizable", "run", fallback: "Run")
  /// Running...
  internal static let running = L10n.tr("Localizable", "running", fallback: "Running...")
  /// Runtime
  internal static let runtime = L10n.tr("Localizable", "runtime", fallback: "Runtime")
  /// Sample
  internal static let sample = L10n.tr("Localizable", "sample", fallback: "Sample")
  /// Save
  internal static let save = L10n.tr("Localizable", "save", fallback: "Save")
  /// Save the user to this device without any local authentication.
  internal static let saveUserWithoutAuthDescription = L10n.tr("Localizable", "saveUserWithoutAuthDescription", fallback: "Save the user to this device without any local authentication.")
  /// Scene
  internal static let scene = L10n.tr("Localizable", "scene", fallback: "Scene")
  /// Schedule already exists
  internal static let scheduleAlreadyExists = L10n.tr("Localizable", "scheduleAlreadyExists", fallback: "Schedule already exists")
  /// Score
  internal static let score = L10n.tr("Localizable", "score", fallback: "Score")
  /// Screenshot
  internal static let screenshot = L10n.tr("Localizable", "screenshot", fallback: "Screenshot")
  /// Scrub
  internal static let scrub = L10n.tr("Localizable", "scrub", fallback: "Scrub")
  /// Search
  internal static let search = L10n.tr("Localizable", "search", fallback: "Search")
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
  /// Security
  internal static let security = L10n.tr("Localizable", "security", fallback: "Security")
  /// See all
  internal static let seeAll = L10n.tr("Localizable", "seeAll", fallback: "See all")
  /// See more
  internal static let seeMore = L10n.tr("Localizable", "seeMore", fallback: "See more")
  /// Select all
  internal static let selectAll = L10n.tr("Localizable", "selectAll", fallback: "Select all")
  /// Select image
  internal static let selectImage = L10n.tr("Localizable", "selectImage", fallback: "Select image")
  /// Select server
  internal static let selectServer = L10n.tr("Localizable", "selectServer", fallback: "Select server")
  /// Series
  internal static let series = L10n.tr("Localizable", "series", fallback: "Series")
  /// Series backdrop
  internal static let seriesBackdrop = L10n.tr("Localizable", "seriesBackdrop", fallback: "Series backdrop")
  /// Series date played
  internal static let seriesDatePlayed = L10n.tr("Localizable", "seriesDatePlayed", fallback: "Series date played")
  /// Series name
  internal static let seriesName = L10n.tr("Localizable", "seriesName", fallback: "Series name")
  /// Server
  internal static let server = L10n.tr("Localizable", "server", fallback: "Server")
  /// Server %s already exists. Add new URL?
  internal static func serverAlreadyExistsPrompt(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "serverAlreadyExistsPrompt", p1, fallback: "Server %s already exists. Add new URL?")
  }
  /// Server logs
  internal static let serverLogs = L10n.tr("Localizable", "serverLogs", fallback: "Server logs")
  /// Servers
  internal static let servers = L10n.tr("Localizable", "servers", fallback: "Servers")
  /// Server URL
  internal static let serverURL = L10n.tr("Localizable", "serverURL", fallback: "Server URL")
  /// Swiftfin requires Jellyfin version %@ or higher.
  internal static func serverVersionWarning(_ p1: Any) -> String {
    return L10n.tr("Localizable", "serverVersionWarning", String(describing: p1), fallback: "Swiftfin requires Jellyfin version %@ or higher.")
  }
  /// Session
  internal static let session = L10n.tr("Localizable", "session", fallback: "Session")
  /// Sessions
  internal static let sessions = L10n.tr("Localizable", "sessions", fallback: "Sessions")
  /// Set
  internal static let `set` = L10n.tr("Localizable", "set", fallback: "Set")
  /// Set pin
  internal static let setPin = L10n.tr("Localizable", "setPin", fallback: "Set pin")
  /// Set a hint when prompting for the pin.
  internal static let setPinHintDescription = L10n.tr("Localizable", "setPinHintDescription", fallback: "Set a hint when prompting for the pin.")
  /// Settings
  internal static let settings = L10n.tr("Localizable", "settings", fallback: "Settings")
  /// Short
  internal static let short = L10n.tr("Localizable", "short", fallback: "Short")
  /// Show favorited
  internal static let showFavorited = L10n.tr("Localizable", "showFavorited", fallback: "Show favorited")
  /// Show favorites
  internal static let showFavorites = L10n.tr("Localizable", "showFavorites", fallback: "Show favorites")
  /// Show missing episodes
  internal static let showMissingEpisodes = L10n.tr("Localizable", "showMissingEpisodes", fallback: "Show missing episodes")
  /// Show missing seasons
  internal static let showMissingSeasons = L10n.tr("Localizable", "showMissingSeasons", fallback: "Show missing seasons")
  /// Show poster labels
  internal static let showPosterLabels = L10n.tr("Localizable", "showPosterLabels", fallback: "Show poster labels")
  /// Show progress
  internal static let showProgress = L10n.tr("Localizable", "showProgress", fallback: "Show progress")
  /// Show Recently Added
  internal static let showRecentlyAdded = L10n.tr("Localizable", "showRecentlyAdded", fallback: "Show Recently Added")
  /// Show unwatched
  internal static let showUnwatched = L10n.tr("Localizable", "showUnwatched", fallback: "Show unwatched")
  /// Show watched
  internal static let showWatched = L10n.tr("Localizable", "showWatched", fallback: "Show watched")
  /// Shutdown server
  internal static let shutdownServer = L10n.tr("Localizable", "shutdownServer", fallback: "Shutdown server")
  /// Are you sure you want to shutdown the server?
  internal static let shutdownWarning = L10n.tr("Localizable", "shutdownWarning", fallback: "Are you sure you want to shutdown the server?")
  /// Sign in
  internal static let signIn = L10n.tr("Localizable", "signIn", fallback: "Sign in")
  /// Sign in to %s
  internal static func signInToServer(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "signInToServer", p1, fallback: "Sign in to %s")
  }
  /// Sign out on background
  internal static let signoutBackground = L10n.tr("Localizable", "signoutBackground", fallback: "Sign out on background")
  /// Signs out the last user when Swiftfin has been in the background without media playback after some time.
  internal static let signoutBackgroundFooter = L10n.tr("Localizable", "signoutBackgroundFooter", fallback: "Signs out the last user when Swiftfin has been in the background without media playback after some time.")
  /// Sign out on close
  internal static let signoutClose = L10n.tr("Localizable", "signoutClose", fallback: "Sign out on close")
  /// Signs out the last user when Swiftfin has been force closed.
  internal static let signoutCloseFooter = L10n.tr("Localizable", "signoutCloseFooter", fallback: "Signs out the last user when Swiftfin has been force closed.")
  /// Slider
  internal static let slider = L10n.tr("Localizable", "slider", fallback: "Slider")
  /// Slow scrub
  internal static let slowScrub = L10n.tr("Localizable", "slowScrub", fallback: "Slow scrub")
  /// Smaller
  internal static let smaller = L10n.tr("Localizable", "smaller", fallback: "Smaller")
  /// Smallest
  internal static let smallest = L10n.tr("Localizable", "smallest", fallback: "Smallest")
  /// Sort
  internal static let sort = L10n.tr("Localizable", "sort", fallback: "Sort")
  /// Sort name
  internal static let sortName = L10n.tr("Localizable", "sortName", fallback: "Sort name")
  /// Sort title
  internal static let sortTitle = L10n.tr("Localizable", "sortTitle", fallback: "Sort title")
  /// Source code
  internal static let sourceCode = L10n.tr("Localizable", "sourceCode", fallback: "Source code")
  /// Special features
  internal static let specialFeatures = L10n.tr("Localizable", "specialFeatures", fallback: "Special features")
  /// Splashscreen
  internal static let splashscreen = L10n.tr("Localizable", "splashscreen", fallback: "Splashscreen")
  /// When all servers are selected, use the splashscreen from a single server or a random server.
  internal static let splashscreenFooter = L10n.tr("Localizable", "splashscreenFooter", fallback: "When all servers are selected, use the splashscreen from a single server or a random server.")
  /// Split
  internal static let split = L10n.tr("Localizable", "split", fallback: "Split")
  /// Sports
  internal static let sports = L10n.tr("Localizable", "sports", fallback: "Sports")
  /// Start date
  internal static let startDate = L10n.tr("Localizable", "startDate", fallback: "Start date")
  /// Start time
  internal static let startTime = L10n.tr("Localizable", "startTime", fallback: "Start time")
  /// Status
  internal static let status = L10n.tr("Localizable", "status", fallback: "Status")
  /// Stop
  internal static let stop = L10n.tr("Localizable", "stop", fallback: "Stop")
  /// Story arc
  internal static let storyArc = L10n.tr("Localizable", "storyArc", fallback: "Story arc")
  /// The stream count exceeds the allowed limit
  internal static let streamCountExceedsLimit = L10n.tr("Localizable", "streamCountExceedsLimit", fallback: "The stream count exceeds the allowed limit")
  /// Streams
  internal static let streams = L10n.tr("Localizable", "streams", fallback: "Streams")
  /// Studio
  internal static let studio = L10n.tr("Localizable", "studio", fallback: "Studio")
  /// Studios
  internal static let studios = L10n.tr("Localizable", "studios", fallback: "Studios")
  /// Studio(s) involved in the creation of media.
  internal static let studiosDescription = L10n.tr("Localizable", "studiosDescription", fallback: "Studio(s) involved in the creation of media.")
  /// Subtitle
  internal static let subtitle = L10n.tr("Localizable", "subtitle", fallback: "Subtitle")
  /// The subtitle codec is not supported
  internal static let subtitleCodecNotSupported = L10n.tr("Localizable", "subtitleCodecNotSupported", fallback: "The subtitle codec is not supported")
  /// Subtitle color
  internal static let subtitleColor = L10n.tr("Localizable", "subtitleColor", fallback: "Subtitle color")
  /// Subtitle font
  internal static let subtitleFont = L10n.tr("Localizable", "subtitleFont", fallback: "Subtitle font")
  /// Subtitles
  internal static let subtitles = L10n.tr("Localizable", "subtitles", fallback: "Subtitles")
  /// Settings only affect some subtitle types
  internal static let subtitlesDisclaimer = L10n.tr("Localizable", "subtitlesDisclaimer", fallback: "Settings only affect some subtitle types")
  /// Subtitle size
  internal static let subtitleSize = L10n.tr("Localizable", "subtitleSize", fallback: "Subtitle size")
  /// Success
  internal static let success = L10n.tr("Localizable", "success", fallback: "Success")
  /// Media control
  internal static let supportsMediaControl = L10n.tr("Localizable", "supportsMediaControl", fallback: "Media control")
  /// Persistent identifier
  internal static let supportsPersistentIdentifier = L10n.tr("Localizable", "supportsPersistentIdentifier", fallback: "Persistent identifier")
  /// Switch user
  internal static let switchUser = L10n.tr("Localizable", "switchUser", fallback: "Switch user")
  /// SyncPlay
  internal static let syncPlay = L10n.tr("Localizable", "syncPlay", fallback: "SyncPlay")
  /// System
  internal static let system = L10n.tr("Localizable", "system", fallback: "System")
  /// Tagline
  internal static let tagline = L10n.tr("Localizable", "tagline", fallback: "Tagline")
  /// Taglines
  internal static let taglines = L10n.tr("Localizable", "taglines", fallback: "Taglines")
  /// Tags
  internal static let tags = L10n.tr("Localizable", "tags", fallback: "Tags")
  /// Labels used to organize or highlight specific attributes of media.
  internal static let tagsDescription = L10n.tr("Localizable", "tagsDescription", fallback: "Labels used to organize or highlight specific attributes of media.")
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
  /// Sets the duration (in minutes) in between task triggers.
  internal static let taskTriggerInterval = L10n.tr("Localizable", "taskTriggerInterval", fallback: "Sets the duration (in minutes) in between task triggers.")
  /// Sets the maximum runtime (in hours) for this task trigger.
  internal static let taskTriggerTimeLimit = L10n.tr("Localizable", "taskTriggerTimeLimit", fallback: "Sets the maximum runtime (in hours) for this task trigger.")
  /// Tbps
  internal static let terabitsPerSecond = L10n.tr("Localizable", "terabitsPerSecond", fallback: "Tbps")
  /// Test size
  internal static let testSize = L10n.tr("Localizable", "testSize", fallback: "Test size")
  /// Theme song
  internal static let themeSong = L10n.tr("Localizable", "themeSong", fallback: "Theme song")
  /// Theme video
  internal static let themeVideo = L10n.tr("Localizable", "themeVideo", fallback: "Theme video")
  /// Thumb
  internal static let thumb = L10n.tr("Localizable", "thumb", fallback: "Thumb")
  /// Time
  internal static let time = L10n.tr("Localizable", "time", fallback: "Time")
  /// Time left
  internal static let timeLeft = L10n.tr("Localizable", "timeLeft", fallback: "Time left")
  /// Time limit
  internal static let timeLimit = L10n.tr("Localizable", "timeLimit", fallback: "Time limit")
  /// Time limit: %1$@
  internal static func timeLimitLabelWithValue(_ p1: Any) -> String {
    return L10n.tr("Localizable", "timeLimitLabelWithValue", String(describing: p1), fallback: "Time limit: %1$@")
  }
  /// Timestamp
  internal static let timestamp = L10n.tr("Localizable", "timestamp", fallback: "Timestamp")
  /// Title
  internal static let title = L10n.tr("Localizable", "title", fallback: "Title")
  /// Total time
  internal static let totalTime = L10n.tr("Localizable", "totalTime", fallback: "Total time")
  /// Trailer
  internal static let trailer = L10n.tr("Localizable", "trailer", fallback: "Trailer")
  /// Trailers
  internal static let trailers = L10n.tr("Localizable", "trailers", fallback: "Trailers")
  /// Trailing value
  internal static let trailingValue = L10n.tr("Localizable", "trailingValue", fallback: "Trailing value")
  /// Transcode
  internal static let transcode = L10n.tr("Localizable", "transcode", fallback: "Transcode")
  /// Transcode reason(s)
  internal static let transcodeReasons = L10n.tr("Localizable", "transcodeReasons", fallback: "Transcode reason(s)")
  /// Translator
  internal static let translator = L10n.tr("Localizable", "translator", fallback: "Translator")
  /// Trigger already exists
  internal static let triggerAlreadyExists = L10n.tr("Localizable", "triggerAlreadyExists", fallback: "Trigger already exists")
  /// Triggers
  internal static let triggers = L10n.tr("Localizable", "triggers", fallback: "Triggers")
  /// TV
  internal static let tv = L10n.tr("Localizable", "tv", fallback: "TV")
  /// TV channel
  internal static let tvChannel = L10n.tr("Localizable", "tvChannel", fallback: "TV channel")
  /// TV channels
  internal static let tvChannels = L10n.tr("Localizable", "tvChannels", fallback: "TV channels")
  /// TV program
  internal static let tvProgram = L10n.tr("Localizable", "tvProgram", fallback: "TV program")
  /// TV programs
  internal static let tvPrograms = L10n.tr("Localizable", "tvPrograms", fallback: "TV programs")
  /// TV shows
  internal static let tvShows = L10n.tr("Localizable", "tvShows", fallback: "TV shows")
  /// TV Shows
  internal static let tvShowsCapitalized = L10n.tr("Localizable", "tvShowsCapitalized", fallback: "TV Shows")
  /// Type
  internal static let type = L10n.tr("Localizable", "type", fallback: "Type")
  /// Unable to find host
  internal static let unableToFindHost = L10n.tr("Localizable", "unableToFindHost", fallback: "Unable to find host")
  /// Unable to open trailer
  internal static let unableToOpenTrailer = L10n.tr("Localizable", "unableToOpenTrailer", fallback: "Unable to open trailer")
  /// Unable to open trailer in %1$@
  internal static func unableToOpenTrailerApp(_ p1: Any) -> String {
    return L10n.tr("Localizable", "unableToOpenTrailerApp", String(describing: p1), fallback: "Unable to open trailer in %1$@")
  }
  /// Unable to perform device authentication
  internal static let unableToPerformDeviceAuth = L10n.tr("Localizable", "unableToPerformDeviceAuth", fallback: "Unable to perform device authentication")
  /// Unable to perform device authentication. You may need to enable Face ID in the Settings app for Swiftfin.
  internal static let unableToPerformDeviceAuthFaceID = L10n.tr("Localizable", "unableToPerformDeviceAuthFaceID", fallback: "Unable to perform device authentication. You may need to enable Face ID in the Settings app for Swiftfin.")
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
  /// Unknown error
  internal static let unknownError = L10n.tr("Localizable", "unknownError", fallback: "Unknown error")
  /// The video stream information is unknown
  internal static let unknownVideoStreamInfo = L10n.tr("Localizable", "unknownVideoStreamInfo", fallback: "The video stream information is unknown")
  /// Unlimited
  internal static let unlimited = L10n.tr("Localizable", "unlimited", fallback: "Unlimited")
  /// The user can connect to the server without any limits.
  internal static let unlimitedConnectionsDescription = L10n.tr("Localizable", "unlimitedConnectionsDescription", fallback: "The user can connect to the server without any limits.")
  /// Allows unlimited failed login attempts without locking the user.
  internal static let unlimitedFailedLoginDescription = L10n.tr("Localizable", "unlimitedFailedLoginDescription", fallback: "Allows unlimited failed login attempts without locking the user.")
  /// Unplayed
  internal static let unplayed = L10n.tr("Localizable", "unplayed", fallback: "Unplayed")
  /// Unreleased
  internal static let unreleased = L10n.tr("Localizable", "unreleased", fallback: "Unreleased")
  /// You have unsaved changes. Are you sure you want to discard them?
  internal static let unsavedChangesMessage = L10n.tr("Localizable", "unsavedChangesMessage", fallback: "You have unsaved changes. Are you sure you want to discard them?")
  /// Upload file
  internal static let uploadFile = L10n.tr("Localizable", "uploadFile", fallback: "Upload file")
  /// Upload photo
  internal static let uploadPhoto = L10n.tr("Localizable", "uploadPhoto", fallback: "Upload photo")
  /// Up to date
  internal static let upToDate = L10n.tr("Localizable", "upToDate", fallback: "Up to date")
  /// URL
  internal static let url = L10n.tr("Localizable", "url", fallback: "URL")
  /// Use as transcoding profile
  internal static let useAsTranscodingProfile = L10n.tr("Localizable", "useAsTranscodingProfile", fallback: "Use as transcoding profile")
  /// Use primary image
  internal static let usePrimaryImage = L10n.tr("Localizable", "usePrimaryImage", fallback: "Use primary image")
  /// Uses the primary image and hides the logo.
  internal static let usePrimaryImageDescription = L10n.tr("Localizable", "usePrimaryImageDescription", fallback: "Uses the primary image and hides the logo.")
  /// User
  internal static let user = L10n.tr("Localizable", "user", fallback: "User")
  /// This user will require device authentication.
  internal static let userDeviceAuthRequiredDescription = L10n.tr("Localizable", "userDeviceAuthRequiredDescription", fallback: "This user will require device authentication.")
  /// Username
  internal static let username = L10n.tr("Localizable", "username", fallback: "Username")
  /// A username is required
  internal static let usernameRequired = L10n.tr("Localizable", "usernameRequired", fallback: "A username is required")
  /// This user will require a pin.
  internal static let userPinRequiredDescription = L10n.tr("Localizable", "userPinRequiredDescription", fallback: "This user will require a pin.")
  /// User %@ requires device authentication
  internal static func userRequiresDeviceAuthentication(_ p1: Any) -> String {
    return L10n.tr("Localizable", "userRequiresDeviceAuthentication", String(describing: p1), fallback: "User %@ requires device authentication")
  }
  /// User root folder
  internal static let userRootFolder = L10n.tr("Localizable", "userRootFolder", fallback: "User root folder")
  /// User root folders
  internal static let userRootFolders = L10n.tr("Localizable", "userRootFolders", fallback: "User root folders")
  /// Users
  internal static let users = L10n.tr("Localizable", "users", fallback: "Users")
  /// User view
  internal static let userView = L10n.tr("Localizable", "userView", fallback: "User view")
  /// User views
  internal static let userViews = L10n.tr("Localizable", "userViews", fallback: "User views")
  /// Use splashscreen
  internal static let useSplashscreen = L10n.tr("Localizable", "useSplashscreen", fallback: "Use splashscreen")
  /// Version
  internal static let version = L10n.tr("Localizable", "version", fallback: "Version")
  /// Video
  internal static let video = L10n.tr("Localizable", "video", fallback: "Video")
  /// The video bit depth is not supported
  internal static let videoBitDepthNotSupported = L10n.tr("Localizable", "videoBitDepthNotSupported", fallback: "The video bit depth is not supported")
  /// Video bitrate
  internal static let videoBitRate = L10n.tr("Localizable", "videoBitRate", fallback: "Video bitrate")
  /// The video bitrate is not supported
  internal static let videoBitrateNotSupported = L10n.tr("Localizable", "videoBitrateNotSupported", fallback: "The video bitrate is not supported")
  /// The video codec is not supported
  internal static let videoCodecNotSupported = L10n.tr("Localizable", "videoCodecNotSupported", fallback: "The video codec is not supported")
  /// Video codec tag is not supported
  internal static let videoCodecTagNotSupported = L10n.tr("Localizable", "videoCodecTagNotSupported", fallback: "Video codec tag is not supported")
  /// The video framerate is not supported
  internal static let videoFramerateNotSupported = L10n.tr("Localizable", "videoFramerateNotSupported", fallback: "The video framerate is not supported")
  /// The video level is not supported
  internal static let videoLevelNotSupported = L10n.tr("Localizable", "videoLevelNotSupported", fallback: "The video level is not supported")
  /// Video player
  internal static let videoPlayer = L10n.tr("Localizable", "videoPlayer", fallback: "Video player")
  /// Video player type
  internal static let videoPlayerType = L10n.tr("Localizable", "videoPlayerType", fallback: "Video player type")
  /// The video profile is not supported
  internal static let videoProfileNotSupported = L10n.tr("Localizable", "videoProfileNotSupported", fallback: "The video profile is not supported")
  /// The video range type is not supported
  internal static let videoRangeTypeNotSupported = L10n.tr("Localizable", "videoRangeTypeNotSupported", fallback: "The video range type is not supported")
  /// Video remuxing
  internal static let videoRemuxing = L10n.tr("Localizable", "videoRemuxing", fallback: "Video remuxing")
  /// The video resolution is not supported
  internal static let videoResolutionNotSupported = L10n.tr("Localizable", "videoResolutionNotSupported", fallback: "The video resolution is not supported")
  /// Videos
  internal static let videos = L10n.tr("Localizable", "videos", fallback: "Videos")
  /// Video transcoding
  internal static let videoTranscoding = L10n.tr("Localizable", "videoTranscoding", fallback: "Video transcoding")
  /// Some views may need an app restart to update.
  internal static let viewsMayRequireRestart = L10n.tr("Localizable", "viewsMayRequireRestart", fallback: "Some views may need an app restart to update.")
  /// Volume
  internal static let volume = L10n.tr("Localizable", "volume", fallback: "Volume")
  /// Votes
  internal static let votes = L10n.tr("Localizable", "votes", fallback: "Votes")
  /// Weekday
  internal static let weekday = L10n.tr("Localizable", "weekday", fallback: "Weekday")
  /// Weekend
  internal static let weekend = L10n.tr("Localizable", "weekend", fallback: "Weekend")
  /// Weekly
  internal static let weekly = L10n.tr("Localizable", "weekly", fallback: "Weekly")
  /// This will be created as a new item on your Jellyfin Server.
  internal static let willBeCreatedOnServer = L10n.tr("Localizable", "willBeCreatedOnServer", fallback: "This will be created as a new item on your Jellyfin Server.")
  /// Writer
  internal static let writer = L10n.tr("Localizable", "writer", fallback: "Writer")
  /// Year
  internal static let year = L10n.tr("Localizable", "year", fallback: "Year")
  /// Years
  internal static let years = L10n.tr("Localizable", "years", fallback: "Years")
  /// %@ years old
  internal static func yearsOld(_ p1: Any) -> String {
    return L10n.tr("Localizable", "yearsOld", String(describing: p1), fallback: "%@ years old")
  }
  /// Yellow
  internal static let yellow = L10n.tr("Localizable", "yellow", fallback: "Yellow")
  /// Yes
  internal static let yes = L10n.tr("Localizable", "yes", fallback: "Yes")
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
