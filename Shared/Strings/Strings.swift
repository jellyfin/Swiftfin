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
  /// Accent Color
  internal static let accentColor = L10n.tr("Localizable", "accentColor", fallback: "Accent Color")
  /// Access
  internal static let access = L10n.tr("Localizable", "access", fallback: "Access")
  /// Accessibility
  internal static let accessibility = L10n.tr("Localizable", "accessibility", fallback: "Accessibility")
  /// The End Time must come after the Start Time.
  internal static let accessScheduleInvalidTime = L10n.tr("Localizable", "accessScheduleInvalidTime", fallback: "The End Time must come after the Start Time.")
  /// Access Schedules
  internal static let accessSchedules = L10n.tr("Localizable", "accessSchedules", fallback: "Access Schedules")
  /// Define the allowed hours for usage and restrict access outside those times.
  internal static let accessSchedulesDescription = L10n.tr("Localizable", "accessSchedulesDescription", fallback: "Define the allowed hours for usage and restrict access outside those times.")
  /// User will have access to no media unless it contains at least one allowed tag.
  internal static let accessTagAllowDescription = L10n.tr("Localizable", "accessTagAllowDescription", fallback: "User will have access to no media unless it contains at least one allowed tag.")
  /// Access tag already exists
  internal static let accessTagAlreadyExists = L10n.tr("Localizable", "accessTagAlreadyExists", fallback: "Access tag already exists")
  /// User will have access to all media except when it contains any blocked tag.
  internal static let accessTagBlockDescription = L10n.tr("Localizable", "accessTagBlockDescription", fallback: "User will have access to all media except when it contains any blocked tag.")
  /// Access Tags
  internal static let accessTags = L10n.tr("Localizable", "accessTags", fallback: "Access Tags")
  /// Use tags to grant or restrict this user's access to media.
  internal static let accessTagsDescription = L10n.tr("Localizable", "accessTagsDescription", fallback: "Use tags to grant or restrict this user's access to media.")
  /// Active
  internal static let active = L10n.tr("Localizable", "active", fallback: "Active")
  /// Activity
  internal static let activity = L10n.tr("Localizable", "activity", fallback: "Activity")
  /// Actor
  internal static let actor = L10n.tr("Localizable", "actor", fallback: "Actor")
  /// Add
  internal static let add = L10n.tr("Localizable", "add", fallback: "Add")
  /// Add access schedule
  internal static let addAccessSchedule = L10n.tr("Localizable", "addAccessSchedule", fallback: "Add access schedule")
  /// Add access tag
  internal static let addAccessTag = L10n.tr("Localizable", "addAccessTag", fallback: "Add access tag")
  /// Add API key
  internal static let addAPIKey = L10n.tr("Localizable", "addAPIKey", fallback: "Add API key")
  /// Additional security access for users signed in to this device. This does not change any Jellyfin server user settings.
  internal static let additionalSecurityAccessDescription = L10n.tr("Localizable", "additionalSecurityAccessDescription", fallback: "Additional security access for users signed in to this device. This does not change any Jellyfin server user settings.")
  /// Add Server
  internal static let addServer = L10n.tr("Localizable", "addServer", fallback: "Add Server")
  /// Add trigger
  internal static let addTrigger = L10n.tr("Localizable", "addTrigger", fallback: "Add trigger")
  /// Add URL
  internal static let addURL = L10n.tr("Localizable", "addURL", fallback: "Add URL")
  /// Add User
  internal static let addUser = L10n.tr("Localizable", "addUser", fallback: "Add User")
  /// Administrator
  internal static let administrator = L10n.tr("Localizable", "administrator", fallback: "Administrator")
  /// Advanced
  internal static let advanced = L10n.tr("Localizable", "advanced", fallback: "Advanced")
  /// Age %@
  internal static func agesGroup(_ p1: Any) -> String {
    return L10n.tr("Localizable", "agesGroup", String(describing: p1), fallback: "Age %@")
  }
  /// Aired
  internal static let aired = L10n.tr("Localizable", "aired", fallback: "Aired")
  /// Air Time
  internal static let airTime = L10n.tr("Localizable", "airTime", fallback: "Air Time")
  /// Airs %s
  internal static func airWithDate(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "airWithDate", p1, fallback: "Airs %s")
  }
  /// Album Artist
  internal static let albumArtist = L10n.tr("Localizable", "albumArtist", fallback: "Album Artist")
  /// All
  internal static let all = L10n.tr("Localizable", "all", fallback: "All")
  /// All Audiences
  internal static let allAudiences = L10n.tr("Localizable", "allAudiences", fallback: "All Audiences")
  /// View all past and present devices that have connected.
  internal static let allDevicesDescription = L10n.tr("Localizable", "allDevicesDescription", fallback: "View all past and present devices that have connected.")
  /// All languages
  internal static let allLanguages = L10n.tr("Localizable", "allLanguages", fallback: "All languages")
  /// All Media
  internal static let allMedia = L10n.tr("Localizable", "allMedia", fallback: "All Media")
  /// Allow collection management
  internal static let allowCollectionManagement = L10n.tr("Localizable", "allowCollectionManagement", fallback: "Allow collection management")
  /// Allowed
  internal static let allowed = L10n.tr("Localizable", "allowed", fallback: "Allowed")
  /// Allow media item deletion
  internal static let allowItemDeletion = L10n.tr("Localizable", "allowItemDeletion", fallback: "Allow media item deletion")
  /// Allow media item editing
  internal static let allowItemEditing = L10n.tr("Localizable", "allowItemEditing", fallback: "Allow media item editing")
  /// All Servers
  internal static let allServers = L10n.tr("Localizable", "allServers", fallback: "All Servers")
  /// View and manage all registered users on the server, including their permissions and activity status.
  internal static let allUsersDescription = L10n.tr("Localizable", "allUsersDescription", fallback: "View and manage all registered users on the server, including their permissions and activity status.")
  /// Alternate
  internal static let alternate = L10n.tr("Localizable", "alternate", fallback: "Alternate")
  /// Alternate DVD
  internal static let alternateDVD = L10n.tr("Localizable", "alternateDVD", fallback: "Alternate DVD")
  /// Anamorphic video is not supported
  internal static let anamorphicVideoNotSupported = L10n.tr("Localizable", "anamorphicVideoNotSupported", fallback: "Anamorphic video is not supported")
  /// API Key Copied
  internal static let apiKeyCopied = L10n.tr("Localizable", "apiKeyCopied", fallback: "API Key Copied")
  /// Your API Key was copied to your clipboard!
  internal static let apiKeyCopiedMessage = L10n.tr("Localizable", "apiKeyCopiedMessage", fallback: "Your API Key was copied to your clipboard!")
  /// API Keys
  internal static let apiKeys = L10n.tr("Localizable", "apiKeys", fallback: "API Keys")
  /// External applications require an API key to communicate with your server.
  internal static let apiKeysDescription = L10n.tr("Localizable", "apiKeysDescription", fallback: "External applications require an API key to communicate with your server.")
  /// API Keys
  internal static let apiKeysTitle = L10n.tr("Localizable", "apiKeysTitle", fallback: "API Keys")
  /// Appearance
  internal static let appearance = L10n.tr("Localizable", "appearance", fallback: "Appearance")
  /// App Icon
  internal static let appIcon = L10n.tr("Localizable", "appIcon", fallback: "App Icon")
  /// Application Name
  internal static let applicationName = L10n.tr("Localizable", "applicationName", fallback: "Application Name")
  /// Arranger
  internal static let arranger = L10n.tr("Localizable", "arranger", fallback: "Arranger")
  /// Art
  internal static let art = L10n.tr("Localizable", "art", fallback: "Art")
  /// Artist
  internal static let artist = L10n.tr("Localizable", "artist", fallback: "Artist")
  /// Aspect Fill
  internal static let aspectFill = L10n.tr("Localizable", "aspectFill", fallback: "Aspect Fill")
  /// Audio
  internal static let audio = L10n.tr("Localizable", "audio", fallback: "Audio")
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
  /// Auto Play
  internal static let autoPlay = L10n.tr("Localizable", "autoPlay", fallback: "Auto Play")
  /// Back
  internal static let back = L10n.tr("Localizable", "back", fallback: "Back")
  /// Backdrop
  internal static let backdrop = L10n.tr("Localizable", "backdrop", fallback: "Backdrop")
  /// Banner
  internal static let banner = L10n.tr("Localizable", "banner", fallback: "Banner")
  /// Bar Buttons
  internal static let barButtons = L10n.tr("Localizable", "barButtons", fallback: "Bar Buttons")
  /// Behavior
  internal static let behavior = L10n.tr("Localizable", "behavior", fallback: "Behavior")
  /// Tests your server connection to assess internet speed and adjust bandwidth automatically.
  internal static let birateAutoDescription = L10n.tr("Localizable", "birateAutoDescription", fallback: "Tests your server connection to assess internet speed and adjust bandwidth automatically.")
  /// Birthday
  internal static let birthday = L10n.tr("Localizable", "birthday", fallback: "Birthday")
  /// Birth year
  internal static let birthYear = L10n.tr("Localizable", "birthYear", fallback: "Birth year")
  /// Auto
  internal static let bitrateAuto = L10n.tr("Localizable", "bitrateAuto", fallback: "Auto")
  /// Default Bitrate
  internal static let bitrateDefault = L10n.tr("Localizable", "bitrateDefault", fallback: "Default Bitrate")
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
  /// Bitrate Test
  internal static let bitrateTest = L10n.tr("Localizable", "bitrateTest", fallback: "Bitrate Test")
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
  /// Books
  internal static let books = L10n.tr("Localizable", "books", fallback: "Books")
  /// Box
  internal static let box = L10n.tr("Localizable", "box", fallback: "Box")
  /// BoxRear
  internal static let boxRear = L10n.tr("Localizable", "boxRear", fallback: "BoxRear")
  /// Bugs and Features
  internal static let bugsAndFeatures = L10n.tr("Localizable", "bugsAndFeatures", fallback: "Bugs and Features")
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
  /// Cast & Crew
  internal static let castAndCrew = L10n.tr("Localizable", "castAndCrew", fallback: "Cast & Crew")
  /// Category
  internal static let category = L10n.tr("Localizable", "category", fallback: "Category")
  /// Change Pin
  internal static let changePin = L10n.tr("Localizable", "changePin", fallback: "Change Pin")
  /// Channels
  internal static let channels = L10n.tr("Localizable", "channels", fallback: "Channels")
  /// Chapter
  internal static let chapter = L10n.tr("Localizable", "chapter", fallback: "Chapter")
  /// Chapters
  internal static let chapters = L10n.tr("Localizable", "chapters", fallback: "Chapters")
  /// Chapter Slider
  internal static let chapterSlider = L10n.tr("Localizable", "chapterSlider", fallback: "Chapter Slider")
  /// Cinematic
  internal static let cinematic = L10n.tr("Localizable", "cinematic", fallback: "Cinematic")
  /// Cinematic Background
  internal static let cinematicBackground = L10n.tr("Localizable", "cinematicBackground", fallback: "Cinematic Background")
  /// Client
  internal static let client = L10n.tr("Localizable", "client", fallback: "Client")
  /// Close
  internal static let close = L10n.tr("Localizable", "close", fallback: "Close")
  /// Collections
  internal static let collections = L10n.tr("Localizable", "collections", fallback: "Collections")
  /// Color
  internal static let color = L10n.tr("Localizable", "color", fallback: "Color")
  /// Colorist
  internal static let colorist = L10n.tr("Localizable", "colorist", fallback: "Colorist")
  /// Columns
  internal static let columns = L10n.tr("Localizable", "columns", fallback: "Columns")
  /// Community
  internal static let community = L10n.tr("Localizable", "community", fallback: "Community")
  /// Community rating
  internal static let communityRating = L10n.tr("Localizable", "communityRating", fallback: "Community rating")
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
  /// Converts all media to H.264 video and AAC audio for maximum compatibility. May require server transcoding for non-compatible media types.
  internal static let compatibleDescription = L10n.tr("Localizable", "compatibleDescription", fallback: "Converts all media to H.264 video and AAC audio for maximum compatibility. May require server transcoding for non-compatible media types.")
  /// Composer
  internal static let composer = L10n.tr("Localizable", "composer", fallback: "Composer")
  /// Conductor
  internal static let conductor = L10n.tr("Localizable", "conductor", fallback: "Conductor")
  /// Confirm
  internal static let confirm = L10n.tr("Localizable", "confirm", fallback: "Confirm")
  /// Confirm New Password
  internal static let confirmNewPassword = L10n.tr("Localizable", "confirmNewPassword", fallback: "Confirm New Password")
  /// Confirm Password
  internal static let confirmPassword = L10n.tr("Localizable", "confirmPassword", fallback: "Confirm Password")
  /// Connect
  internal static let connect = L10n.tr("Localizable", "connect", fallback: "Connect")
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
  /// Continuing
  internal static let continuing = L10n.tr("Localizable", "continuing", fallback: "Continuing")
  /// Control other users
  internal static let controlOtherUsers = L10n.tr("Localizable", "controlOtherUsers", fallback: "Control other users")
  /// Control shared devices
  internal static let controlSharedDevices = L10n.tr("Localizable", "controlSharedDevices", fallback: "Control shared devices")
  /// Country
  internal static let country = L10n.tr("Localizable", "country", fallback: "Country")
  /// Cover Artist
  internal static let coverArtist = L10n.tr("Localizable", "coverArtist", fallback: "Cover Artist")
  /// Create & Join Groups
  internal static let createAndJoinGroups = L10n.tr("Localizable", "createAndJoinGroups", fallback: "Create & Join Groups")
  /// Create API Key
  internal static let createAPIKey = L10n.tr("Localizable", "createAPIKey", fallback: "Create API Key")
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
  /// Critics
  internal static let critics = L10n.tr("Localizable", "critics", fallback: "Critics")
  /// Current
  internal static let current = L10n.tr("Localizable", "current", fallback: "Current")
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
  /// Custom Device Name
  internal static let customDeviceName = L10n.tr("Localizable", "customDeviceName", fallback: "Custom Device Name")
  /// Your custom device name '%1$@' has been saved.
  internal static func customDeviceNameSaved(_ p1: Any) -> String {
    return L10n.tr("Localizable", "customDeviceNameSaved", String(describing: p1), fallback: "Your custom device name '%1$@' has been saved.")
  }
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
  /// Date Added
  internal static let dateAdded = L10n.tr("Localizable", "dateAdded", fallback: "Date Added")
  /// Date created
  internal static let dateCreated = L10n.tr("Localizable", "dateCreated", fallback: "Date created")
  /// Date modified
  internal static let dateModified = L10n.tr("Localizable", "dateModified", fallback: "Date modified")
  /// Date of death
  internal static let dateOfDeath = L10n.tr("Localizable", "dateOfDeath", fallback: "Date of death")
  /// Dates
  internal static let dates = L10n.tr("Localizable", "dates", fallback: "Dates")
  /// Day of Week
  internal static let dayOfWeek = L10n.tr("Localizable", "dayOfWeek", fallback: "Day of Week")
  /// Days
  internal static let days = L10n.tr("Localizable", "days", fallback: "Days")
  /// Default
  internal static let `default` = L10n.tr("Localizable", "default", fallback: "Default")
  /// Admins are locked out after 5 failed attempts. Non-admins are locked out after 3 attempts.
  internal static let defaultFailedLoginDescription = L10n.tr("Localizable", "defaultFailedLoginDescription", fallback: "Admins are locked out after 5 failed attempts. Non-admins are locked out after 3 attempts.")
  /// Delete
  internal static let delete = L10n.tr("Localizable", "delete", fallback: "Delete")
  /// Are you sure you want to permanently delete this key?
  internal static let deleteAPIKeyMessage = L10n.tr("Localizable", "deleteAPIKeyMessage", fallback: "Are you sure you want to permanently delete this key?")
  /// Delete Device
  internal static let deleteDevice = L10n.tr("Localizable", "deleteDevice", fallback: "Delete Device")
  /// Failed to Delete Device
  internal static let deleteDeviceFailed = L10n.tr("Localizable", "deleteDeviceFailed", fallback: "Failed to Delete Device")
  /// Cannot delete a session from the same device (%1$@).
  internal static func deleteDeviceSelfDeletion(_ p1: Any) -> String {
    return L10n.tr("Localizable", "deleteDeviceSelfDeletion", String(describing: p1), fallback: "Cannot delete a session from the same device (%1$@).")
  }
  /// Are you sure you wish to delete this device? This session will be logged out.
  internal static let deleteDeviceWarning = L10n.tr("Localizable", "deleteDeviceWarning", fallback: "Are you sure you wish to delete this device? This session will be logged out.")
  /// Delete image
  internal static let deleteImage = L10n.tr("Localizable", "deleteImage", fallback: "Delete image")
  /// Are you sure you want to delete this item?
  internal static let deleteItemConfirmation = L10n.tr("Localizable", "deleteItemConfirmation", fallback: "Are you sure you want to delete this item?")
  /// Are you sure you want to delete this item? This action cannot be undone.
  internal static let deleteItemConfirmationMessage = L10n.tr("Localizable", "deleteItemConfirmationMessage", fallback: "Are you sure you want to delete this item? This action cannot be undone.")
  /// Delete Schedule
  internal static let deleteSchedule = L10n.tr("Localizable", "deleteSchedule", fallback: "Delete Schedule")
  /// Are you sure you wish to delete this schedule?
  internal static let deleteScheduleWarning = L10n.tr("Localizable", "deleteScheduleWarning", fallback: "Are you sure you wish to delete this schedule?")
  /// Are you sure you want to delete the selected items?
  internal static let deleteSelectedConfirmation = L10n.tr("Localizable", "deleteSelectedConfirmation", fallback: "Are you sure you want to delete the selected items?")
  /// Delete Selected Devices
  internal static let deleteSelectedDevices = L10n.tr("Localizable", "deleteSelectedDevices", fallback: "Delete Selected Devices")
  /// Delete Selected Schedules
  internal static let deleteSelectedSchedules = L10n.tr("Localizable", "deleteSelectedSchedules", fallback: "Delete Selected Schedules")
  /// Delete Selected Users
  internal static let deleteSelectedUsers = L10n.tr("Localizable", "deleteSelectedUsers", fallback: "Delete Selected Users")
  /// Are you sure you wish to delete all selected devices? All selected sessions will be logged out.
  internal static let deleteSelectionDevicesWarning = L10n.tr("Localizable", "deleteSelectionDevicesWarning", fallback: "Are you sure you wish to delete all selected devices? All selected sessions will be logged out.")
  /// Are you sure you wish to delete all selected schedules?
  internal static let deleteSelectionSchedulesWarning = L10n.tr("Localizable", "deleteSelectionSchedulesWarning", fallback: "Are you sure you wish to delete all selected schedules?")
  /// Are you sure you wish to delete all selected users?
  internal static let deleteSelectionUsersWarning = L10n.tr("Localizable", "deleteSelectionUsersWarning", fallback: "Are you sure you wish to delete all selected users?")
  /// Delete Server
  internal static let deleteServer = L10n.tr("Localizable", "deleteServer", fallback: "Delete Server")
  /// Delete Trigger
  internal static let deleteTrigger = L10n.tr("Localizable", "deleteTrigger", fallback: "Delete Trigger")
  /// Are you sure you want to delete this trigger? This action cannot be undone.
  internal static let deleteTriggerConfirmationMessage = L10n.tr("Localizable", "deleteTriggerConfirmationMessage", fallback: "Are you sure you want to delete this trigger? This action cannot be undone.")
  /// Delete User
  internal static let deleteUser = L10n.tr("Localizable", "deleteUser", fallback: "Delete User")
  /// Failed to Delete User
  internal static let deleteUserFailed = L10n.tr("Localizable", "deleteUserFailed", fallback: "Failed to Delete User")
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
  /// Details
  internal static let details = L10n.tr("Localizable", "details", fallback: "Details")
  /// Device
  internal static let device = L10n.tr("Localizable", "device", fallback: "Device")
  /// Device Access
  internal static let deviceAccess = L10n.tr("Localizable", "deviceAccess", fallback: "Device Access")
  /// Device authentication failed
  internal static let deviceAuthFailed = L10n.tr("Localizable", "deviceAuthFailed", fallback: "Device authentication failed")
  /// Device Profile
  internal static let deviceProfile = L10n.tr("Localizable", "deviceProfile", fallback: "Device Profile")
  /// Decide which media plays natively or requires server transcoding for compatibility.
  internal static let deviceProfileDescription = L10n.tr("Localizable", "deviceProfileDescription", fallback: "Decide which media plays natively or requires server transcoding for compatibility.")
  /// Devices
  internal static let devices = L10n.tr("Localizable", "devices", fallback: "Devices")
  /// Digital
  internal static let digital = L10n.tr("Localizable", "digital", fallback: "Digital")
  /// Dimensions
  internal static let dimensions = L10n.tr("Localizable", "dimensions", fallback: "Dimensions")
  /// Direct Play
  internal static let direct = L10n.tr("Localizable", "direct", fallback: "Direct Play")
  /// Plays content in its original format. May cause playback issues on unsupported media types.
  internal static let directDescription = L10n.tr("Localizable", "directDescription", fallback: "Plays content in its original format. May cause playback issues on unsupported media types.")
  /// Director
  internal static let director = L10n.tr("Localizable", "director", fallback: "Director")
  /// Direct Play
  internal static let directPlay = L10n.tr("Localizable", "directPlay", fallback: "Direct Play")
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
  /// Display Order
  internal static let displayOrder = L10n.tr("Localizable", "displayOrder", fallback: "Display Order")
  /// Done
  internal static let done = L10n.tr("Localizable", "done", fallback: "Done")
  /// Downloads
  internal static let downloads = L10n.tr("Localizable", "downloads", fallback: "Downloads")
  /// Duplicate User
  internal static let duplicateUser = L10n.tr("Localizable", "duplicateUser", fallback: "Duplicate User")
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
  /// Editor
  internal static let editor = L10n.tr("Localizable", "editor", fallback: "Editor")
  /// Edit Server
  internal static let editServer = L10n.tr("Localizable", "editServer", fallback: "Edit Server")
  /// Edit Users
  internal static let editUsers = L10n.tr("Localizable", "editUsers", fallback: "Edit Users")
  /// Enable all devices
  internal static let enableAllDevices = L10n.tr("Localizable", "enableAllDevices", fallback: "Enable all devices")
  /// Enable all libraries
  internal static let enableAllLibraries = L10n.tr("Localizable", "enableAllLibraries", fallback: "Enable all libraries")
  /// Enabled
  internal static let enabled = L10n.tr("Localizable", "enabled", fallback: "Enabled")
  /// End Date
  internal static let endDate = L10n.tr("Localizable", "endDate", fallback: "End Date")
  /// Ended
  internal static let ended = L10n.tr("Localizable", "ended", fallback: "Ended")
  /// End Time
  internal static let endTime = L10n.tr("Localizable", "endTime", fallback: "End Time")
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
  /// Enter Pin
  internal static let enterPin = L10n.tr("Localizable", "enterPin", fallback: "Enter Pin")
  /// Enter PIN for %@
  internal static func enterPinForUser(_ p1: Any) -> String {
    return L10n.tr("Localizable", "enterPinForUser", String(describing: p1), fallback: "Enter PIN for %@")
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
  /// Error Details
  internal static let errorDetails = L10n.tr("Localizable", "errorDetails", fallback: "Error Details")
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
  /// Failed logins
  internal static let failedLogins = L10n.tr("Localizable", "failedLogins", fallback: "Failed logins")
  /// Favorited
  internal static let favorited = L10n.tr("Localizable", "favorited", fallback: "Favorited")
  /// Favorites
  internal static let favorites = L10n.tr("Localizable", "favorites", fallback: "Favorites")
  /// Filters
  internal static let filters = L10n.tr("Localizable", "filters", fallback: "Filters")
  /// Find Missing
  internal static let findMissing = L10n.tr("Localizable", "findMissing", fallback: "Find Missing")
  /// Find missing metadata and images.
  internal static let findMissingDescription = L10n.tr("Localizable", "findMissingDescription", fallback: "Find missing metadata and images.")
  /// Force remote media transcoding
  internal static let forceRemoteTranscoding = L10n.tr("Localizable", "forceRemoteTranscoding", fallback: "Force remote media transcoding")
  /// Format
  internal static let format = L10n.tr("Localizable", "format", fallback: "Format")
  /// 3D Format
  internal static let format3D = L10n.tr("Localizable", "format3D", fallback: "3D Format")
  /// Full Side-by-Side
  internal static let fullSideBySide = L10n.tr("Localizable", "fullSideBySide", fallback: "Full Side-by-Side")
  /// Full Top and Bottom
  internal static let fullTopAndBottom = L10n.tr("Localizable", "fullTopAndBottom", fallback: "Full Top and Bottom")
  /// Genres
  internal static let genres = L10n.tr("Localizable", "genres", fallback: "Genres")
  /// Categories that describe the themes or styles of media.
  internal static let genresDescription = L10n.tr("Localizable", "genresDescription", fallback: "Categories that describe the themes or styles of media.")
  /// Gestures
  internal static let gestures = L10n.tr("Localizable", "gestures", fallback: "Gestures")
  /// Gbps
  internal static let gigabitsPerSecond = L10n.tr("Localizable", "gigabitsPerSecond", fallback: "Gbps")
  /// Green
  internal static let green = L10n.tr("Localizable", "green", fallback: "Green")
  /// Grid
  internal static let grid = L10n.tr("Localizable", "grid", fallback: "Grid")
  /// Guest Star
  internal static let guestStar = L10n.tr("Localizable", "guestStar", fallback: "Guest Star")
  /// Half Side-by-Side
  internal static let halfSideBySide = L10n.tr("Localizable", "halfSideBySide", fallback: "Half Side-by-Side")
  /// Half Top and Bottom
  internal static let halfTopAndBottom = L10n.tr("Localizable", "halfTopAndBottom", fallback: "Half Top and Bottom")
  /// Hidden
  internal static let hidden = L10n.tr("Localizable", "hidden", fallback: "Hidden")
  /// Hide user from login screen
  internal static let hideUserFromLoginScreen = L10n.tr("Localizable", "hideUserFromLoginScreen", fallback: "Hide user from login screen")
  /// Hint
  internal static let hint = L10n.tr("Localizable", "hint", fallback: "Hint")
  /// Home
  internal static let home = L10n.tr("Localizable", "home", fallback: "Home")
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
  /// Index
  internal static let index = L10n.tr("Localizable", "index", fallback: "Index")
  /// Indicators
  internal static let indicators = L10n.tr("Localizable", "indicators", fallback: "Indicators")
  /// Inker
  internal static let inker = L10n.tr("Localizable", "inker", fallback: "Inker")
  /// Interlaced video is not supported
  internal static let interlacedVideoNotSupported = L10n.tr("Localizable", "interlacedVideoNotSupported", fallback: "Interlaced video is not supported")
  /// Interval
  internal static let interval = L10n.tr("Localizable", "interval", fallback: "Interval")
  /// Inverted Dark
  internal static let invertedDark = L10n.tr("Localizable", "invertedDark", fallback: "Inverted Dark")
  /// Inverted Light
  internal static let invertedLight = L10n.tr("Localizable", "invertedLight", fallback: "Inverted Light")
  /// %1$@ at %2$@
  internal static func itemAtItem(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "itemAtItem", String(describing: p1), String(describing: p2), fallback: "%1$@ at %2$@")
  }
  /// Items
  internal static let items = L10n.tr("Localizable", "items", fallback: "Items")
  /// Jellyfin
  internal static let jellyfin = L10n.tr("Localizable", "jellyfin", fallback: "Jellyfin")
  /// Join Groups
  internal static let joinGroups = L10n.tr("Localizable", "joinGroups", fallback: "Join Groups")
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
  /// Kids
  internal static let kids = L10n.tr("Localizable", "kids", fallback: "Kids")
  /// kbps
  internal static let kilobitsPerSecond = L10n.tr("Localizable", "kilobitsPerSecond", fallback: "kbps")
  /// Language
  internal static let language = L10n.tr("Localizable", "language", fallback: "Language")
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
  /// Layout
  internal static let layout = L10n.tr("Localizable", "layout", fallback: "Layout")
  /// Learn more...
  internal static let learnMoreEllipsis = L10n.tr("Localizable", "learnMoreEllipsis", fallback: "Learn more...")
  /// Left
  internal static let `left` = L10n.tr("Localizable", "left", fallback: "Left")
  /// Letter
  internal static let letter = L10n.tr("Localizable", "letter", fallback: "Letter")
  /// Letterer
  internal static let letterer = L10n.tr("Localizable", "letterer", fallback: "Letterer")
  /// Letter Picker
  internal static let letterPicker = L10n.tr("Localizable", "letterPicker", fallback: "Letter Picker")
  /// Library
  internal static let library = L10n.tr("Localizable", "library", fallback: "Library")
  /// Light
  internal static let light = L10n.tr("Localizable", "light", fallback: "Light")
  /// Liked Items
  internal static let likedItems = L10n.tr("Localizable", "likedItems", fallback: "Liked Items")
  /// Likes
  internal static let likes = L10n.tr("Localizable", "likes", fallback: "Likes")
  /// List
  internal static let list = L10n.tr("Localizable", "list", fallback: "List")
  /// Live TV
  internal static let liveTV = L10n.tr("Localizable", "liveTV", fallback: "Live TV")
  /// Live TV access
  internal static let liveTvAccess = L10n.tr("Localizable", "liveTvAccess", fallback: "Live TV access")
  /// Live TV Channels
  internal static let liveTVChannels = L10n.tr("Localizable", "liveTVChannels", fallback: "Live TV Channels")
  /// Live TV Programs
  internal static let liveTVPrograms = L10n.tr("Localizable", "liveTVPrograms", fallback: "Live TV Programs")
  /// Live TV recording management
  internal static let liveTvRecordingManagement = L10n.tr("Localizable", "liveTvRecordingManagement", fallback: "Live TV recording management")
  /// Loading user failed
  internal static let loadingUserFailed = L10n.tr("Localizable", "loadingUserFailed", fallback: "Loading user failed")
  /// Local Servers
  internal static let localServers = L10n.tr("Localizable", "localServers", fallback: "Local Servers")
  /// Lock All Fields
  internal static let lockAllFields = L10n.tr("Localizable", "lockAllFields", fallback: "Lock All Fields")
  /// Locked Fields
  internal static let lockedFields = L10n.tr("Localizable", "lockedFields", fallback: "Locked Fields")
  /// Locked users
  internal static let lockedUsers = L10n.tr("Localizable", "lockedUsers", fallback: "Locked users")
  /// Logo
  internal static let logo = L10n.tr("Localizable", "logo", fallback: "Logo")
  /// Logs
  internal static let logs = L10n.tr("Localizable", "logs", fallback: "Logs")
  /// Access the Jellyfin server logs for troubleshooting and monitoring purposes.
  internal static let logsDescription = L10n.tr("Localizable", "logsDescription", fallback: "Access the Jellyfin server logs for troubleshooting and monitoring purposes.")
  /// Lyricist
  internal static let lyricist = L10n.tr("Localizable", "lyricist", fallback: "Lyricist")
  /// Lyrics
  internal static let lyrics = L10n.tr("Localizable", "lyrics", fallback: "Lyrics")
  /// Management
  internal static let management = L10n.tr("Localizable", "management", fallback: "Management")
  /// Maximum Bitrate
  internal static let maximumBitrate = L10n.tr("Localizable", "maximumBitrate", fallback: "Maximum Bitrate")
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
  /// Media Access
  internal static let mediaAccess = L10n.tr("Localizable", "mediaAccess", fallback: "Media Access")
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
  /// Menu Buttons
  internal static let menuButtons = L10n.tr("Localizable", "menuButtons", fallback: "Menu Buttons")
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
  /// Missing Items
  internal static let missingItems = L10n.tr("Localizable", "missingItems", fallback: "Missing Items")
  /// Mixer
  internal static let mixer = L10n.tr("Localizable", "mixer", fallback: "Mixer")
  /// Movies
  internal static let movies = L10n.tr("Localizable", "movies", fallback: "Movies")
  /// Music
  internal static let music = L10n.tr("Localizable", "music", fallback: "Music")
  /// MVC
  internal static let mvc = L10n.tr("Localizable", "mvc", fallback: "MVC")
  /// Name
  internal static let name = L10n.tr("Localizable", "name", fallback: "Name")
  /// Native Player
  internal static let nativePlayer = L10n.tr("Localizable", "nativePlayer", fallback: "Native Player")
  /// Network timed out
  internal static let networkTimedOut = L10n.tr("Localizable", "networkTimedOut", fallback: "Network timed out")
  /// Never
  internal static let never = L10n.tr("Localizable", "never", fallback: "Never")
  /// Never run
  internal static let neverRun = L10n.tr("Localizable", "neverRun", fallback: "Never run")
  /// New Password
  internal static let newPassword = L10n.tr("Localizable", "newPassword", fallback: "New Password")
  /// News
  internal static let news = L10n.tr("Localizable", "news", fallback: "News")
  /// New User
  internal static let newUser = L10n.tr("Localizable", "newUser", fallback: "New User")
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
  /// No
  internal static let no = L10n.tr("Localizable", "no", fallback: "No")
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
  /// No runtime limit
  internal static let noRuntimeLimit = L10n.tr("Localizable", "noRuntimeLimit", fallback: "No runtime limit")
  /// No session
  internal static let noSession = L10n.tr("Localizable", "noSession", fallback: "No session")
  /// Type: %@ not implemented yet :(
  internal static func notImplementedYetWithType(_ p1: Any) -> String {
    return L10n.tr("Localizable", "notImplementedYetWithType", String(describing: p1), fallback: "Type: %@ not implemented yet :(")
  }
  /// No title
  internal static let noTitle = L10n.tr("Localizable", "noTitle", fallback: "No title")
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
  /// Original Air Date
  internal static let originalAirDate = L10n.tr("Localizable", "originalAirDate", fallback: "Original Air Date")
  /// Original aspect ratio
  internal static let originalAspectRatio = L10n.tr("Localizable", "originalAspectRatio", fallback: "Original aspect ratio")
  /// Original Title
  internal static let originalTitle = L10n.tr("Localizable", "originalTitle", fallback: "Original Title")
  /// Other
  internal static let other = L10n.tr("Localizable", "other", fallback: "Other")
  /// Overview
  internal static let overview = L10n.tr("Localizable", "overview", fallback: "Overview")
  /// Parental controls
  internal static let parentalControls = L10n.tr("Localizable", "parentalControls", fallback: "Parental controls")
  /// Parental rating
  internal static let parentalRating = L10n.tr("Localizable", "parentalRating", fallback: "Parental rating")
  /// Password
  internal static let password = L10n.tr("Localizable", "password", fallback: "Password")
  /// User password has been changed.
  internal static let passwordChangedMessage = L10n.tr("Localizable", "passwordChangedMessage", fallback: "User password has been changed.")
  /// Changes the Jellyfin server user password. This does not change any Swiftfin settings.
  internal static let passwordChangeWarning = L10n.tr("Localizable", "passwordChangeWarning", fallback: "Changes the Jellyfin server user password. This does not change any Swiftfin settings.")
  /// New passwords do not match.
  internal static let passwordsDoNotMatch = L10n.tr("Localizable", "passwordsDoNotMatch", fallback: "New passwords do not match.")
  /// Pause on background
  internal static let pauseOnBackground = L10n.tr("Localizable", "pauseOnBackground", fallback: "Pause on background")
  /// Penciller
  internal static let penciller = L10n.tr("Localizable", "penciller", fallback: "Penciller")
  /// People
  internal static let people = L10n.tr("Localizable", "people", fallback: "People")
  /// People who helped create or perform specific media.
  internal static let peopleDescription = L10n.tr("Localizable", "peopleDescription", fallback: "People who helped create or perform specific media.")
  /// Permissions
  internal static let permissions = L10n.tr("Localizable", "permissions", fallback: "Permissions")
  /// Pin
  internal static let pin = L10n.tr("Localizable", "pin", fallback: "Pin")
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
  /// Playback Speed
  internal static let playbackSpeed = L10n.tr("Localizable", "playbackSpeed", fallback: "Playback Speed")
  /// Played
  internal static let played = L10n.tr("Localizable", "played", fallback: "Played")
  /// Play From Beginning
  internal static let playFromBeginning = L10n.tr("Localizable", "playFromBeginning", fallback: "Play From Beginning")
  /// Play Next Item
  internal static let playNextItem = L10n.tr("Localizable", "playNextItem", fallback: "Play Next Item")
  /// Play on active
  internal static let playOnActive = L10n.tr("Localizable", "playOnActive", fallback: "Play on active")
  /// Play Previous Item
  internal static let playPreviousItem = L10n.tr("Localizable", "playPreviousItem", fallback: "Play Previous Item")
  /// Posters
  internal static let posters = L10n.tr("Localizable", "posters", fallback: "Posters")
  /// Premiere Date
  internal static let premiereDate = L10n.tr("Localizable", "premiereDate", fallback: "Premiere Date")
  /// Press Down for Menu
  internal static let pressDownForMenu = L10n.tr("Localizable", "pressDownForMenu", fallback: "Press Down for Menu")
  /// Previous Item
  internal static let previousItem = L10n.tr("Localizable", "previousItem", fallback: "Previous Item")
  /// Primary
  internal static let primary = L10n.tr("Localizable", "primary", fallback: "Primary")
  /// Producer
  internal static let producer = L10n.tr("Localizable", "producer", fallback: "Producer")
  /// Production
  internal static let production = L10n.tr("Localizable", "production", fallback: "Production")
  /// Production Locations
  internal static let productionLocations = L10n.tr("Localizable", "productionLocations", fallback: "Production Locations")
  /// Production Year
  internal static let productionYear = L10n.tr("Localizable", "productionYear", fallback: "Production Year")
  /// Profile
  internal static let profile = L10n.tr("Localizable", "profile", fallback: "Profile")
  /// Profile Image
  internal static let profileImage = L10n.tr("Localizable", "profileImage", fallback: "Profile Image")
  /// Profiles
  internal static let profiles = L10n.tr("Localizable", "profiles", fallback: "Profiles")
  /// Programs
  internal static let programs = L10n.tr("Localizable", "programs", fallback: "Programs")
  /// Progress
  internal static let progress = L10n.tr("Localizable", "progress", fallback: "Progress")
  /// Provider
  internal static let provider = L10n.tr("Localizable", "provider", fallback: "Provider")
  /// Public Users
  internal static let publicUsers = L10n.tr("Localizable", "publicUsers", fallback: "Public Users")
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
  /// Random
  internal static let random = L10n.tr("Localizable", "random", fallback: "Random")
  /// Random image
  internal static let randomImage = L10n.tr("Localizable", "randomImage", fallback: "Random image")
  /// Rating
  internal static let rating = L10n.tr("Localizable", "rating", fallback: "Rating")
  /// %@ rating on a scale from 1 to 10.
  internal static func ratingDescription(_ p1: Any) -> String {
    return L10n.tr("Localizable", "ratingDescription", String(describing: p1), fallback: "%@ rating on a scale from 1 to 10.")
  }
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
  /// Refresh Metadata
  internal static let refreshMetadata = L10n.tr("Localizable", "refreshMetadata", fallback: "Refresh Metadata")
  /// Regional
  internal static let regional = L10n.tr("Localizable", "regional", fallback: "Regional")
  /// Regular
  internal static let regular = L10n.tr("Localizable", "regular", fallback: "Regular")
  /// Release Date
  internal static let releaseDate = L10n.tr("Localizable", "releaseDate", fallback: "Release Date")
  /// Remember layout
  internal static let rememberLayout = L10n.tr("Localizable", "rememberLayout", fallback: "Remember layout")
  /// Remember layout for individual libraries
  internal static let rememberLayoutFooter = L10n.tr("Localizable", "rememberLayoutFooter", fallback: "Remember layout for individual libraries")
  /// Remember sorting
  internal static let rememberSorting = L10n.tr("Localizable", "rememberSorting", fallback: "Remember sorting")
  /// Remember sorting for individual libraries
  internal static let rememberSortingFooter = L10n.tr("Localizable", "rememberSortingFooter", fallback: "Remember sorting for individual libraries")
  /// Remixer
  internal static let remixer = L10n.tr("Localizable", "remixer", fallback: "Remixer")
  /// Remote connections
  internal static let remoteConnections = L10n.tr("Localizable", "remoteConnections", fallback: "Remote connections")
  /// Remote control
  internal static let remoteControl = L10n.tr("Localizable", "remoteControl", fallback: "Remote control")
  /// Remove All
  internal static let removeAll = L10n.tr("Localizable", "removeAll", fallback: "Remove All")
  /// Remove All Servers
  internal static let removeAllServers = L10n.tr("Localizable", "removeAllServers", fallback: "Remove All Servers")
  /// Remux
  internal static let remux = L10n.tr("Localizable", "remux", fallback: "Remux")
  /// Reorder
  internal static let reorder = L10n.tr("Localizable", "reorder", fallback: "Reorder")
  /// Replace All
  internal static let replaceAll = L10n.tr("Localizable", "replaceAll", fallback: "Replace All")
  /// Replace all unlocked metadata and images with new information.
  internal static let replaceAllDescription = L10n.tr("Localizable", "replaceAllDescription", fallback: "Replace all unlocked metadata and images with new information.")
  /// Replace Images
  internal static let replaceImages = L10n.tr("Localizable", "replaceImages", fallback: "Replace Images")
  /// Replace all images with new images.
  internal static let replaceImagesDescription = L10n.tr("Localizable", "replaceImagesDescription", fallback: "Replace all images with new images.")
  /// Replace Metadata
  internal static let replaceMetadata = L10n.tr("Localizable", "replaceMetadata", fallback: "Replace Metadata")
  /// Replace unlocked metadata with new information.
  internal static let replaceMetadataDescription = L10n.tr("Localizable", "replaceMetadataDescription", fallback: "Replace unlocked metadata with new information.")
  /// Required
  internal static let `required` = L10n.tr("Localizable", "required", fallback: "Required")
  /// Require device authentication when signing in to the user.
  internal static let requireDeviceAuthDescription = L10n.tr("Localizable", "requireDeviceAuthDescription", fallback: "Require device authentication when signing in to the user.")
  /// Require device authentication to sign in to the Quick Connect user on this device.
  internal static let requireDeviceAuthForQuickConnectUser = L10n.tr("Localizable", "requireDeviceAuthForQuickConnectUser", fallback: "Require device authentication to sign in to the Quick Connect user on this device.")
  /// Require device authentication to sign in to %@ on this device.
  internal static func requireDeviceAuthForUser(_ p1: Any) -> String {
    return L10n.tr("Localizable", "requireDeviceAuthForUser", String(describing: p1), fallback: "Require device authentication to sign in to %@ on this device.")
  }
  /// Require a local pin when signing in to the user. This pin is unrecoverable.
  internal static let requirePinDescription = L10n.tr("Localizable", "requirePinDescription", fallback: "Require a local pin when signing in to the user. This pin is unrecoverable.")
  /// Reset
  internal static let reset = L10n.tr("Localizable", "reset", fallback: "Reset")
  /// Reset all settings back to defaults.
  internal static let resetAllSettings = L10n.tr("Localizable", "resetAllSettings", fallback: "Reset all settings back to defaults.")
  /// Reset Settings
  internal static let resetSettings = L10n.tr("Localizable", "resetSettings", fallback: "Reset Settings")
  /// Reset Swiftfin user settings
  internal static let resetSettingsDescription = L10n.tr("Localizable", "resetSettingsDescription", fallback: "Reset Swiftfin user settings")
  /// Are you sure you want to reset all user settings?
  internal static let resetSettingsMessage = L10n.tr("Localizable", "resetSettingsMessage", fallback: "Are you sure you want to reset all user settings?")
  /// Reset User Settings
  internal static let resetUserSettings = L10n.tr("Localizable", "resetUserSettings", fallback: "Reset User Settings")
  /// Restart Server
  internal static let restartServer = L10n.tr("Localizable", "restartServer", fallback: "Restart Server")
  /// Are you sure you want to restart the server?
  internal static let restartWarning = L10n.tr("Localizable", "restartWarning", fallback: "Are you sure you want to restart the server?")
  /// Resume
  internal static let resume = L10n.tr("Localizable", "resume", fallback: "Resume")
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
  /// Reviews
  internal static let reviews = L10n.tr("Localizable", "reviews", fallback: "Reviews")
  /// Right
  internal static let `right` = L10n.tr("Localizable", "right", fallback: "Right")
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
  /// Save
  internal static let save = L10n.tr("Localizable", "save", fallback: "Save")
  /// Save the user to this device without any local authentication.
  internal static let saveUserWithoutAuthDescription = L10n.tr("Localizable", "saveUserWithoutAuthDescription", fallback: "Save the user to this device without any local authentication.")
  /// Schedule already exists
  internal static let scheduleAlreadyExists = L10n.tr("Localizable", "scheduleAlreadyExists", fallback: "Schedule already exists")
  /// Score
  internal static let score = L10n.tr("Localizable", "score", fallback: "Score")
  /// Screenshot
  internal static let screenshot = L10n.tr("Localizable", "screenshot", fallback: "Screenshot")
  /// Scrub Current Time
  internal static let scrubCurrentTime = L10n.tr("Localizable", "scrubCurrentTime", fallback: "Scrub Current Time")
  /// Search
  internal static let search = L10n.tr("Localizable", "search", fallback: "Search")
  /// Season
  internal static let season = L10n.tr("Localizable", "season", fallback: "Season")
  /// S%1$@:E%2$@
  internal static func seasonAndEpisode(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "seasonAndEpisode", String(describing: p1), String(describing: p2), fallback: "S%1$@:E%2$@")
  }
  /// Secondary audio is not supported
  internal static let secondaryAudioNotSupported = L10n.tr("Localizable", "secondaryAudioNotSupported", fallback: "Secondary audio is not supported")
  /// Security
  internal static let security = L10n.tr("Localizable", "security", fallback: "Security")
  /// See All
  internal static let seeAll = L10n.tr("Localizable", "seeAll", fallback: "See All")
  /// See More
  internal static let seeMore = L10n.tr("Localizable", "seeMore", fallback: "See More")
  /// Select All
  internal static let selectAll = L10n.tr("Localizable", "selectAll", fallback: "Select All")
  /// Select Image
  internal static let selectImage = L10n.tr("Localizable", "selectImage", fallback: "Select Image")
  /// Select server
  internal static let selectServer = L10n.tr("Localizable", "selectServer", fallback: "Select server")
  /// Series
  internal static let series = L10n.tr("Localizable", "series", fallback: "Series")
  /// Series Backdrop
  internal static let seriesBackdrop = L10n.tr("Localizable", "seriesBackdrop", fallback: "Series Backdrop")
  /// Server
  internal static let server = L10n.tr("Localizable", "server", fallback: "Server")
  /// %@ is already connected.
  internal static func serverAlreadyConnected(_ p1: Any) -> String {
    return L10n.tr("Localizable", "serverAlreadyConnected", String(describing: p1), fallback: "%@ is already connected.")
  }
  /// Server %s already exists. Add new URL?
  internal static func serverAlreadyExistsPrompt(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "serverAlreadyExistsPrompt", p1, fallback: "Server %s already exists. Add new URL?")
  }
  /// Server Logs
  internal static let serverLogs = L10n.tr("Localizable", "serverLogs", fallback: "Server Logs")
  /// Servers
  internal static let servers = L10n.tr("Localizable", "servers", fallback: "Servers")
  /// Server URL
  internal static let serverURL = L10n.tr("Localizable", "serverURL", fallback: "Server URL")
  /// Session
  internal static let session = L10n.tr("Localizable", "session", fallback: "Session")
  /// Sessions
  internal static let sessions = L10n.tr("Localizable", "sessions", fallback: "Sessions")
  /// Set
  internal static let `set` = L10n.tr("Localizable", "set", fallback: "Set")
  /// Set Pin
  internal static let setPin = L10n.tr("Localizable", "setPin", fallback: "Set Pin")
  /// Set pin for new user.
  internal static let setPinForNewUser = L10n.tr("Localizable", "setPinForNewUser", fallback: "Set pin for new user.")
  /// Set a hint when prompting for the pin.
  internal static let setPinHintDescription = L10n.tr("Localizable", "setPinHintDescription", fallback: "Set a hint when prompting for the pin.")
  /// Settings
  internal static let settings = L10n.tr("Localizable", "settings", fallback: "Settings")
  /// Show Favorited
  internal static let showFavorited = L10n.tr("Localizable", "showFavorited", fallback: "Show Favorited")
  /// Show Favorites
  internal static let showFavorites = L10n.tr("Localizable", "showFavorites", fallback: "Show Favorites")
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
  /// Sign In
  internal static let signIn = L10n.tr("Localizable", "signIn", fallback: "Sign In")
  /// Sign In to %s
  internal static func signInToServer(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "signInToServer", p1, fallback: "Sign In to %s")
  }
  /// Sign out on background
  internal static let signoutBackground = L10n.tr("Localizable", "signoutBackground", fallback: "Sign out on background")
  /// Signs out the last user when Swiftfin has been in the background without media playback after some time
  internal static let signoutBackgroundFooter = L10n.tr("Localizable", "signoutBackgroundFooter", fallback: "Signs out the last user when Swiftfin has been in the background without media playback after some time")
  /// Sign out on close
  internal static let signoutClose = L10n.tr("Localizable", "signoutClose", fallback: "Sign out on close")
  /// Signs out the last user when Swiftfin has been force closed
  internal static let signoutCloseFooter = L10n.tr("Localizable", "signoutCloseFooter", fallback: "Signs out the last user when Swiftfin has been force closed")
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
  /// Sort Name
  internal static let sortName = L10n.tr("Localizable", "sortName", fallback: "Sort Name")
  /// Sort Title
  internal static let sortTitle = L10n.tr("Localizable", "sortTitle", fallback: "Sort Title")
  /// Source Code
  internal static let sourceCode = L10n.tr("Localizable", "sourceCode", fallback: "Source Code")
  /// Special Features
  internal static let specialFeatures = L10n.tr("Localizable", "specialFeatures", fallback: "Special Features")
  /// Splashscreen
  internal static let splashscreen = L10n.tr("Localizable", "splashscreen", fallback: "Splashscreen")
  /// When All Servers is selected, use the splashscreen from a single server or a random server
  internal static let splashscreenFooter = L10n.tr("Localizable", "splashscreenFooter", fallback: "When All Servers is selected, use the splashscreen from a single server or a random server")
  /// Sports
  internal static let sports = L10n.tr("Localizable", "sports", fallback: "Sports")
  /// Start Time
  internal static let startTime = L10n.tr("Localizable", "startTime", fallback: "Start Time")
  /// Status
  internal static let status = L10n.tr("Localizable", "status", fallback: "Status")
  /// Stop
  internal static let stop = L10n.tr("Localizable", "stop", fallback: "Stop")
  /// Story Arc
  internal static let storyArc = L10n.tr("Localizable", "storyArc", fallback: "Story Arc")
  /// Streams
  internal static let streams = L10n.tr("Localizable", "streams", fallback: "Streams")
  /// Studios
  internal static let studios = L10n.tr("Localizable", "studios", fallback: "Studios")
  /// Studio(s) involved in the creation of media.
  internal static let studiosDescription = L10n.tr("Localizable", "studiosDescription", fallback: "Studio(s) involved in the creation of media.")
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
  /// Success
  internal static let success = L10n.tr("Localizable", "success", fallback: "Success")
  /// Content Uploading
  internal static let supportsContentUploading = L10n.tr("Localizable", "supportsContentUploading", fallback: "Content Uploading")
  /// Media Control
  internal static let supportsMediaControl = L10n.tr("Localizable", "supportsMediaControl", fallback: "Media Control")
  /// Persistent Identifier
  internal static let supportsPersistentIdentifier = L10n.tr("Localizable", "supportsPersistentIdentifier", fallback: "Persistent Identifier")
  /// Sync
  internal static let supportsSync = L10n.tr("Localizable", "supportsSync", fallback: "Sync")
  /// Switch User
  internal static let switchUser = L10n.tr("Localizable", "switchUser", fallback: "Switch User")
  /// SyncPlay
  internal static let syncPlay = L10n.tr("Localizable", "syncPlay", fallback: "SyncPlay")
  /// System
  internal static let system = L10n.tr("Localizable", "system", fallback: "System")
  /// Tag
  internal static let tag = L10n.tr("Localizable", "tag", fallback: "Tag")
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
  /// Test Size
  internal static let testSize = L10n.tr("Localizable", "testSize", fallback: "Test Size")
  /// Thumb
  internal static let thumb = L10n.tr("Localizable", "thumb", fallback: "Thumb")
  /// Time
  internal static let time = L10n.tr("Localizable", "time", fallback: "Time")
  /// Time Limit
  internal static let timeLimit = L10n.tr("Localizable", "timeLimit", fallback: "Time Limit")
  /// Time limit: %1$@
  internal static func timeLimitLabelWithValue(_ p1: Any) -> String {
    return L10n.tr("Localizable", "timeLimitLabelWithValue", String(describing: p1), fallback: "Time limit: %1$@")
  }
  /// Timestamp
  internal static let timestamp = L10n.tr("Localizable", "timestamp", fallback: "Timestamp")
  /// Timestamp Type
  internal static let timestampType = L10n.tr("Localizable", "timestampType", fallback: "Timestamp Type")
  /// Title
  internal static let title = L10n.tr("Localizable", "title", fallback: "Title")
  /// Trailers
  internal static let trailers = L10n.tr("Localizable", "trailers", fallback: "Trailers")
  /// Trailing Value
  internal static let trailingValue = L10n.tr("Localizable", "trailingValue", fallback: "Trailing Value")
  /// Transcode
  internal static let transcode = L10n.tr("Localizable", "transcode", fallback: "Transcode")
  /// Transcode Reason(s)
  internal static let transcodeReasons = L10n.tr("Localizable", "transcodeReasons", fallback: "Transcode Reason(s)")
  /// Transition
  internal static let transition = L10n.tr("Localizable", "transition", fallback: "Transition")
  /// Translator
  internal static let translator = L10n.tr("Localizable", "translator", fallback: "Translator")
  /// Trigger already exists
  internal static let triggerAlreadyExists = L10n.tr("Localizable", "triggerAlreadyExists", fallback: "Trigger already exists")
  /// Triggers
  internal static let triggers = L10n.tr("Localizable", "triggers", fallback: "Triggers")
  /// TV
  internal static let tv = L10n.tr("Localizable", "tv", fallback: "TV")
  /// TV Access
  internal static let tvAccess = L10n.tr("Localizable", "tvAccess", fallback: "TV Access")
  /// TV Shows
  internal static let tvShows = L10n.tr("Localizable", "tvShows", fallback: "TV Shows")
  /// Type
  internal static let type = L10n.tr("Localizable", "type", fallback: "Type")
  /// Unable to find host
  internal static let unableToFindHost = L10n.tr("Localizable", "unableToFindHost", fallback: "Unable to find host")
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
  /// Unknown Error
  internal static let unknownError = L10n.tr("Localizable", "unknownError", fallback: "Unknown Error")
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
  /// Users
  internal static let users = L10n.tr("Localizable", "users", fallback: "Users")
  /// Use splashscreen
  internal static let useSplashscreen = L10n.tr("Localizable", "useSplashscreen", fallback: "Use splashscreen")
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
  /// Video remuxing
  internal static let videoRemuxing = L10n.tr("Localizable", "videoRemuxing", fallback: "Video remuxing")
  /// The video resolution is not supported
  internal static let videoResolutionNotSupported = L10n.tr("Localizable", "videoResolutionNotSupported", fallback: "The video resolution is not supported")
  /// Video transcoding
  internal static let videoTranscoding = L10n.tr("Localizable", "videoTranscoding", fallback: "Video transcoding")
  /// Some views may need an app restart to update.
  internal static let viewsMayRequireRestart = L10n.tr("Localizable", "viewsMayRequireRestart", fallback: "Some views may need an app restart to update.")
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
