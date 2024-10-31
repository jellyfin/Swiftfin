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
  /// Active
  internal static let active = L10n.tr("Localizable", "active", fallback: "Active")
  /// ActiveSessionsView Header
  internal static let activeDevices = L10n.tr("Localizable", "activeDevices", fallback: "Active Devices")
  /// Activity
  internal static let activity = L10n.tr("Localizable", "activity", fallback: "Activity")
  /// Add
  internal static let add = L10n.tr("Localizable", "add", fallback: "Add")
  /// Add API key
  internal static let addAPIKey = L10n.tr("Localizable", "addAPIKey", fallback: "Add API key")
  /// Select Server View - Add Server
  internal static let addServer = L10n.tr("Localizable", "addServer", fallback: "Add Server")
  /// Add trigger
  internal static let addTrigger = L10n.tr("Localizable", "addTrigger", fallback: "Add trigger")
  /// Add URL
  internal static let addURL = L10n.tr("Localizable", "addURL", fallback: "Add URL")
  /// Add User
  internal static let addUser = L10n.tr("Localizable", "addUser", fallback: "Add User")
  /// Administration Dashboard Section
  internal static let administration = L10n.tr("Localizable", "administration", fallback: "Administration")
  /// Administrator
  internal static let administrator = L10n.tr("Localizable", "administrator", fallback: "Administrator")
  /// Advanced
  internal static let advanced = L10n.tr("Localizable", "advanced", fallback: "Advanced")
  /// Airs %s
  internal static func airWithDate(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "airWithDate", p1, fallback: "Airs %s")
  }
  /// View all past and present devices that have connected.
  internal static let allDevicesDescription = L10n.tr("Localizable", "allDevicesDescription", fallback: "View all past and present devices that have connected.")
  /// All Genres
  internal static let allGenres = L10n.tr("Localizable", "allGenres", fallback: "All Genres")
  /// All Media
  internal static let allMedia = L10n.tr("Localizable", "allMedia", fallback: "All Media")
  /// Select Server View - Select All Servers
  internal static let allServers = L10n.tr("Localizable", "allServers", fallback: "All Servers")
  /// View and manage all registered users on the server, including their permissions and activity status.
  internal static let allUsersDescription = L10n.tr("Localizable", "allUsersDescription", fallback: "View and manage all registered users on the server, including their permissions and activity status.")
  /// TranscodeReason - Anamorphic Video Not Supported
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
  /// Represents the Appearance setting label
  internal static let appearance = L10n.tr("Localizable", "appearance", fallback: "Appearance")
  /// App Icon
  internal static let appIcon = L10n.tr("Localizable", "appIcon", fallback: "App Icon")
  /// Application Name
  internal static let applicationName = L10n.tr("Localizable", "applicationName", fallback: "Application Name")
  /// Apply
  internal static let apply = L10n.tr("Localizable", "apply", fallback: "Apply")
  /// Aspect Fill
  internal static let aspectFill = L10n.tr("Localizable", "aspectFill", fallback: "Aspect Fill")
  /// Audio
  internal static let audio = L10n.tr("Localizable", "audio", fallback: "Audio")
  /// Audio & Captions
  internal static let audioAndCaptions = L10n.tr("Localizable", "audioAndCaptions", fallback: "Audio & Captions")
  /// TranscodeReason - Audio Bit Depth Not Supported
  internal static let audioBitDepthNotSupported = L10n.tr("Localizable", "audioBitDepthNotSupported", fallback: "The audio bit depth is not supported")
  /// TranscodeReason - Audio Bitrate Not Supported
  internal static let audioBitrateNotSupported = L10n.tr("Localizable", "audioBitrateNotSupported", fallback: "The audio bitrate is not supported")
  /// TranscodeReason - Audio Channels Not Supported
  internal static let audioChannelsNotSupported = L10n.tr("Localizable", "audioChannelsNotSupported", fallback: "The number of audio channels is not supported")
  /// TranscodeReason - Audio Codec Not Supported
  internal static let audioCodecNotSupported = L10n.tr("Localizable", "audioCodecNotSupported", fallback: "The audio codec is not supported")
  /// TranscodeReason - Audio Is External
  internal static let audioIsExternal = L10n.tr("Localizable", "audioIsExternal", fallback: "The audio track is external and requires transcoding")
  /// Audio Offset
  internal static let audioOffset = L10n.tr("Localizable", "audioOffset", fallback: "Audio Offset")
  /// TranscodeReason - Audio Profile Not Supported
  internal static let audioProfileNotSupported = L10n.tr("Localizable", "audioProfileNotSupported", fallback: "The audio profile is not supported")
  /// TranscodeReason - Audio Sample Rate Not Supported
  internal static let audioSampleRateNotSupported = L10n.tr("Localizable", "audioSampleRateNotSupported", fallback: "The audio sample rate is not supported")
  /// Audio Track
  internal static let audioTrack = L10n.tr("Localizable", "audioTrack", fallback: "Audio Track")
  /// Authorize
  internal static let authorize = L10n.tr("Localizable", "authorize", fallback: "Authorize")
  /// PlaybackCompatibility Default Category
  internal static let auto = L10n.tr("Localizable", "auto", fallback: "Auto")
  /// Auto Play
  internal static let autoPlay = L10n.tr("Localizable", "autoPlay", fallback: "Auto Play")
  /// Back
  internal static let back = L10n.tr("Localizable", "back", fallback: "Back")
  /// Bar Buttons
  internal static let barButtons = L10n.tr("Localizable", "barButtons", fallback: "Bar Buttons")
  /// Behavior
  internal static let behavior = L10n.tr("Localizable", "behavior", fallback: "Behavior")
  /// Option for automatic bitrate selection
  internal static let bitrateAuto = L10n.tr("Localizable", "bitrateAuto", fallback: "Auto")
  /// Default Bitrate
  internal static let bitrateDefault = L10n.tr("Localizable", "bitrateDefault", fallback: "Default Bitrate")
  /// Default Bitrate Description
  internal static let bitrateDefaultDescription = L10n.tr("Localizable", "bitrateDefaultDescription", fallback: "Limits the internet bandwidth used during video playback")
  /// Option to set the bitrate to 480p quality at 1.5 Mbps
  internal static let bitrateKbps1500 = L10n.tr("Localizable", "bitrateKbps1500", fallback: "480p - 1.5 Mbps")
  /// Option to set the bitrate to 360p quality at 420 Kbps
  internal static let bitrateKbps420 = L10n.tr("Localizable", "bitrateKbps420", fallback: "360p - 420 Kbps")
  /// Option to set the bitrate to 480p quality at 720 Kbps
  internal static let bitrateKbps720 = L10n.tr("Localizable", "bitrateKbps720", fallback: "480p - 720 Kbps")
  /// Option for the maximum bitrate
  internal static let bitrateMax = L10n.tr("Localizable", "bitrateMax", fallback: "Maximum")
  /// Option to set the bitrate to 1080p quality at 10 Mbps
  internal static let bitrateMbps10 = L10n.tr("Localizable", "bitrateMbps10", fallback: "1080p - 10 Mbps")
  /// Option to set the bitrate to 4K quality at 120 Mbps
  internal static let bitrateMbps120 = L10n.tr("Localizable", "bitrateMbps120", fallback: "4K - 120 Mbps")
  /// Option to set the bitrate to 1080p quality at 15 Mbps
  internal static let bitrateMbps15 = L10n.tr("Localizable", "bitrateMbps15", fallback: "1080p - 15 Mbps")
  /// Option to set the bitrate to 1080p quality at 20 Mbps
  internal static let bitrateMbps20 = L10n.tr("Localizable", "bitrateMbps20", fallback: "1080p - 20 Mbps")
  /// Option to set the bitrate to 480p quality at 3 Mbps
  internal static let bitrateMbps3 = L10n.tr("Localizable", "bitrateMbps3", fallback: "480p - 3 Mbps")
  /// Option to set the bitrate to 720p quality at 4 Mbps
  internal static let bitrateMbps4 = L10n.tr("Localizable", "bitrateMbps4", fallback: "720p - 4 Mbps")
  /// Option to set the bitrate to 1080p quality at 40 Mbps
  internal static let bitrateMbps40 = L10n.tr("Localizable", "bitrateMbps40", fallback: "1080p - 40 Mbps")
  /// Option to set the bitrate to 720p quality at 6 Mbps
  internal static let bitrateMbps6 = L10n.tr("Localizable", "bitrateMbps6", fallback: "720p - 6 Mbps")
  /// Option to set the bitrate to 1080p quality at 60 Mbps
  internal static let bitrateMbps60 = L10n.tr("Localizable", "bitrateMbps60", fallback: "1080p - 60 Mbps")
  /// Option to set the bitrate to 720p quality at 8 Mbps
  internal static let bitrateMbps8 = L10n.tr("Localizable", "bitrateMbps8", fallback: "720p - 8 Mbps")
  /// Option to set the bitrate to 4K quality at 80 Mbps
  internal static let bitrateMbps80 = L10n.tr("Localizable", "bitrateMbps80", fallback: "4K - 80 Mbps")
  /// Bitrate Automatic Section Header
  internal static let bitrateTest = L10n.tr("Localizable", "bitrateTest", fallback: "Bitrate Test")
  /// Description for bitrate test duration description
  internal static let bitrateTestDescription = L10n.tr("Localizable", "bitrateTestDescription", fallback: "Determines the length of the 'Auto' bitrate test used to find the available internet bandwidth")
  /// Description for bitrate test duration indicating longer tests provide more accurate bitrates but may delay playback
  internal static let bitrateTestDisclaimer = L10n.tr("Localizable", "bitrateTestDisclaimer", fallback: "Longer tests are more accurate but may result in a delayed playback")
  /// Blue
  internal static let blue = L10n.tr("Localizable", "blue", fallback: "Blue")
  /// Bugs and Features
  internal static let bugsAndFeatures = L10n.tr("Localizable", "bugsAndFeatures", fallback: "Bugs and Features")
  /// Buttons
  internal static let buttons = L10n.tr("Localizable", "buttons", fallback: "Buttons")
  /// Cancel
  internal static let cancel = L10n.tr("Localizable", "cancel", fallback: "Cancel")
  /// Task was Canceled
  internal static let canceled = L10n.tr("Localizable", "canceled", fallback: "Cancelled")
  /// Status label for when a task is cancelling
  internal static let cancelling = L10n.tr("Localizable", "cancelling", fallback: "Cancelling...")
  /// Cannot connect to host
  internal static let cannotConnectToHost = L10n.tr("Localizable", "cannotConnectToHost", fallback: "Cannot connect to host")
  /// Capabilities
  internal static let capabilities = L10n.tr("Localizable", "capabilities", fallback: "Capabilities")
  /// CAST
  internal static let cast = L10n.tr("Localizable", "cast", fallback: "CAST")
  /// Cast & Crew
  internal static let castAndCrew = L10n.tr("Localizable", "castAndCrew", fallback: "Cast & Crew")
  /// The category label for tasks
  internal static let category = L10n.tr("Localizable", "category", fallback: "Category")
  /// Change Server
  internal static let changeServer = L10n.tr("Localizable", "changeServer", fallback: "Change Server")
  /// Changes not saved
  internal static let changesNotSaved = L10n.tr("Localizable", "changesNotSaved", fallback: "Changes not saved")
  /// Channels
  internal static let channels = L10n.tr("Localizable", "channels", fallback: "Channels")
  /// Chapters
  internal static let chapters = L10n.tr("Localizable", "chapters", fallback: "Chapters")
  /// Chapter Slider
  internal static let chapterSlider = L10n.tr("Localizable", "chapterSlider", fallback: "Chapter Slider")
  /// Cinematic
  internal static let cinematic = L10n.tr("Localizable", "cinematic", fallback: "Cinematic")
  /// Customize Server View - Cinematic Background
  internal static let cinematicBackground = L10n.tr("Localizable", "cinematicBackground", fallback: "Cinematic Background")
  /// Cinematic Views
  internal static let cinematicViews = L10n.tr("Localizable", "cinematicViews", fallback: "Cinematic Views")
  /// The client used for the session
  internal static let client = L10n.tr("Localizable", "client", fallback: "Client")
  /// Close
  internal static let close = L10n.tr("Localizable", "close", fallback: "Close")
  /// Closed Captions
  internal static let closedCaptions = L10n.tr("Localizable", "closedCaptions", fallback: "Closed Captions")
  /// Collections
  internal static let collections = L10n.tr("Localizable", "collections", fallback: "Collections")
  /// Color
  internal static let color = L10n.tr("Localizable", "color", fallback: "Color")
  /// Section Title for Column Configuration
  internal static let columns = L10n.tr("Localizable", "columns", fallback: "Columns")
  /// Coming soon
  internal static let comingSoon = L10n.tr("Localizable", "comingSoon", fallback: "Coming soon")
  /// Compact
  internal static let compact = L10n.tr("Localizable", "compact", fallback: "Compact")
  /// Compact Logo
  internal static let compactLogo = L10n.tr("Localizable", "compactLogo", fallback: "Compact Logo")
  /// Compact Poster
  internal static let compactPoster = L10n.tr("Localizable", "compactPoster", fallback: "Compact Poster")
  /// PlaybackCompatibility Section Title
  internal static let compatibility = L10n.tr("Localizable", "compatibility", fallback: "Compatibility")
  /// PlaybackCompatibility Compatible Category
  internal static let compatible = L10n.tr("Localizable", "compatible", fallback: "Most Compatible")
  /// Confirm Task Fuction
  internal static let confirm = L10n.tr("Localizable", "confirm", fallback: "Confirm")
  /// Confirm Close
  internal static let confirmClose = L10n.tr("Localizable", "confirmClose", fallback: "Confirm Close")
  /// Confirm Password
  internal static let confirmPassword = L10n.tr("Localizable", "confirmPassword", fallback: "Confirm Password")
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
  /// TranscodeReason - Container Bitrate Exceeds Limit
  internal static let containerBitrateExceedsLimit = L10n.tr("Localizable", "containerBitrateExceedsLimit", fallback: "The container bitrate exceeds the allowed limit")
  /// TranscodeReason - Container Not Supported
  internal static let containerNotSupported = L10n.tr("Localizable", "containerNotSupported", fallback: "The container format is not supported")
  /// Containers
  internal static let containers = L10n.tr("Localizable", "containers", fallback: "Containers")
  /// Continue
  internal static let `continue` = L10n.tr("Localizable", "continue", fallback: "Continue")
  /// Continue Watching
  internal static let continueWatching = L10n.tr("Localizable", "continueWatching", fallback: "Continue Watching")
  /// Create API Key
  internal static let createAPIKey = L10n.tr("Localizable", "createAPIKey", fallback: "Create API Key")
  /// Enter the application name for the new API key.
  internal static let createAPIKeyMessage = L10n.tr("Localizable", "createAPIKeyMessage", fallback: "Enter the application name for the new API key.")
  /// Current
  internal static let current = L10n.tr("Localizable", "current", fallback: "Current")
  /// Current Position
  internal static let currentPosition = L10n.tr("Localizable", "currentPosition", fallback: "Current Position")
  /// PlaybackCompatibility Custom Category
  internal static let custom = L10n.tr("Localizable", "custom", fallback: "Custom")
  /// Custom Device Name
  internal static let customDeviceName = L10n.tr("Localizable", "customDeviceName", fallback: "Custom Device Name")
  /// Your custom device name '%1$@' has been saved.
  internal static func customDeviceNameSaved(_ p1: Any) -> String {
    return L10n.tr("Localizable", "customDeviceNameSaved", String(describing: p1), fallback: "Your custom device name '%1$@' has been saved.")
  }
  /// Custom profile is Added to the Existing Profiles
  internal static let customDeviceProfileAdd = L10n.tr("Localizable", "customDeviceProfileAdd", fallback: "The custom device profiles will be added to the default Swiftfin device profiles")
  /// Device Profile Section Description
  internal static let customDeviceProfileDescription = L10n.tr("Localizable", "customDeviceProfileDescription", fallback: "Dictates back to the Jellyfin Server what this device hardware is capable of playing")
  /// Custom profile will replace the Existing Profiles
  internal static let customDeviceProfileReplace = L10n.tr("Localizable", "customDeviceProfileReplace", fallback: "The custom device profiles will replace the default Swiftfin device profiles")
  /// Settings View - Customize
  internal static let customize = L10n.tr("Localizable", "customize", fallback: "Customize")
  /// Section Header for a Custom Device Profile
  internal static let customProfile = L10n.tr("Localizable", "customProfile", fallback: "Custom Profile")
  /// Daily
  internal static let daily = L10n.tr("Localizable", "daily", fallback: "Daily")
  /// Represents the dark theme setting
  internal static let dark = L10n.tr("Localizable", "dark", fallback: "Dark")
  /// UserDashboardView Header
  internal static let dashboard = L10n.tr("Localizable", "dashboard", fallback: "Dashboard")
  /// Description for the dashboard section
  internal static let dashboardDescription = L10n.tr("Localizable", "dashboardDescription", fallback: "Perform administrative tasks for your Jellyfin server.")
  /// Date Created
  internal static let dateCreated = L10n.tr("Localizable", "dateCreated", fallback: "Date Created")
  /// Day of Week
  internal static let dayOfWeek = L10n.tr("Localizable", "dayOfWeek", fallback: "Day of Week")
  /// Time Interval Help Text - Days
  internal static let days = L10n.tr("Localizable", "days", fallback: "Days")
  /// Default Scheme
  internal static let defaultScheme = L10n.tr("Localizable", "defaultScheme", fallback: "Default Scheme")
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
  /// Delete Selected Devices
  internal static let deleteSelectedDevices = L10n.tr("Localizable", "deleteSelectedDevices", fallback: "Delete Selected Devices")
  /// Delete Selected Users
  internal static let deleteSelectedUsers = L10n.tr("Localizable", "deleteSelectedUsers", fallback: "Delete Selected Users")
  /// Are you sure you wish to delete all selected devices? All selected sessions will be logged out.
  internal static let deleteSelectionDevicesWarning = L10n.tr("Localizable", "deleteSelectionDevicesWarning", fallback: "Are you sure you wish to delete all selected devices? All selected sessions will be logged out.")
  /// Are you sure you wish to delete all selected users?
  internal static let deleteSelectionUsersWarning = L10n.tr("Localizable", "deleteSelectionUsersWarning", fallback: "Are you sure you wish to delete all selected users?")
  /// Server Detail View - Delete Server
  internal static let deleteServer = L10n.tr("Localizable", "deleteServer", fallback: "Delete Server")
  /// Delete Trigger
  internal static let deleteTrigger = L10n.tr("Localizable", "deleteTrigger", fallback: "Delete Trigger")
  /// Are you sure you want to delete this trigger? This action cannot be undone.
  internal static let deleteTriggerConfirmationMessage = L10n.tr("Localizable", "deleteTriggerConfirmationMessage", fallback: "Are you sure you want to delete this trigger? This action cannot be undone.")
  /// Delete User
  internal static let deleteUser = L10n.tr("Localizable", "deleteUser", fallback: "Delete User")
  /// Failed to Delete User
  internal static let deleteUserFailed = L10n.tr("Localizable", "deleteUserFailed", fallback: "Failed to Delete User")
  /// Cannot delete a user from the same user (%1$@).
  internal static func deleteUserSelfDeletion(_ p1: Any) -> String {
    return L10n.tr("Localizable", "deleteUserSelfDeletion", String(describing: p1), fallback: "Cannot delete a user from the same user (%1$@).")
  }
  /// Are you sure you wish to delete this user?
  internal static let deleteUserWarning = L10n.tr("Localizable", "deleteUserWarning", fallback: "Are you sure you wish to delete this user?")
  /// Delivery
  internal static let delivery = L10n.tr("Localizable", "delivery", fallback: "Delivery")
  /// Details
  internal static let details = L10n.tr("Localizable", "details", fallback: "Details")
  /// Session Device Section Label
  internal static let device = L10n.tr("Localizable", "device", fallback: "Device")
  /// Section Header for Device Profiles
  internal static let deviceProfile = L10n.tr("Localizable", "deviceProfile", fallback: "Device Profile")
  /// Devices
  internal static let devices = L10n.tr("Localizable", "devices", fallback: "Devices")
  /// PlaybackCompatibility DirectPlay Category
  internal static let direct = L10n.tr("Localizable", "direct", fallback: "Direct Play")
  /// DIRECTOR
  internal static let director = L10n.tr("Localizable", "director", fallback: "DIRECTOR")
  /// PlayMethod - Direct Play
  internal static let directPlay = L10n.tr("Localizable", "directPlay", fallback: "Direct Play")
  /// TranscodeReason - Direct Play Error
  internal static let directPlayError = L10n.tr("Localizable", "directPlayError", fallback: "An error occurred during direct play")
  /// PlayMethod - Direct Stream
  internal static let directStream = L10n.tr("Localizable", "directStream", fallback: "Direct Stream")
  /// Disabled
  internal static let disabled = L10n.tr("Localizable", "disabled", fallback: "Disabled")
  /// Discard Changes
  internal static let discardChanges = L10n.tr("Localizable", "discardChanges", fallback: "Discard Changes")
  /// Discovered Servers
  internal static let discoveredServers = L10n.tr("Localizable", "discoveredServers", fallback: "Discovered Servers")
  /// Dismiss
  internal static let dismiss = L10n.tr("Localizable", "dismiss", fallback: "Dismiss")
  /// Display order
  internal static let displayOrder = L10n.tr("Localizable", "displayOrder", fallback: "Display order")
  /// Done - Completed, end, or save
  internal static let done = L10n.tr("Localizable", "done", fallback: "Done")
  /// Downloads
  internal static let downloads = L10n.tr("Localizable", "downloads", fallback: "Downloads")
  /// Button label to edit a task
  internal static let edit = L10n.tr("Localizable", "edit", fallback: "Edit")
  /// Edit Jump Lengths
  internal static let editJumpLengths = L10n.tr("Localizable", "editJumpLengths", fallback: "Edit Jump Lengths")
  /// Select Server View - Edit an Existing Server
  internal static let editServer = L10n.tr("Localizable", "editServer", fallback: "Edit Server")
  /// Edit Users
  internal static let editUsers = L10n.tr("Localizable", "editUsers", fallback: "Edit Users")
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
  /// Error Details
  internal static let errorDetails = L10n.tr("Localizable", "errorDetails", fallback: "Error Details")
  /// Every
  internal static let every = L10n.tr("Localizable", "every", fallback: "Every")
  /// Every %1$@
  internal static func everyInterval(_ p1: Any) -> String {
    return L10n.tr("Localizable", "everyInterval", String(describing: p1), fallback: "Every %1$@")
  }
  /// Executed
  internal static let executed = L10n.tr("Localizable", "executed", fallback: "Executed")
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
  /// Transcode FPS
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
  /// Hidden
  internal static let hidden = L10n.tr("Localizable", "hidden", fallback: "Hidden")
  /// Home
  internal static let home = L10n.tr("Localizable", "home", fallback: "Home")
  /// Hours
  internal static let hours = L10n.tr("Localizable", "hours", fallback: "Hours")
  /// Idle
  internal static let idle = L10n.tr("Localizable", "idle", fallback: "Idle")
  /// Customize Server View - Indicators
  internal static let indicators = L10n.tr("Localizable", "indicators", fallback: "Indicators")
  /// Information
  internal static let information = L10n.tr("Localizable", "information", fallback: "Information")
  /// TranscodeReason - Interlaced Video Not Supported
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
  /// SessionPlaybackMethod Remaining Time
  internal static func itemOverItem(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "itemOverItem", String(describing: p1), String(describing: p2), fallback: "%1$@ / %2$@")
  }
  /// Items
  internal static let items = L10n.tr("Localizable", "items", fallback: "Items")
  /// General
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
  /// The label for the last run time of a task
  internal static let lastRun = L10n.tr("Localizable", "lastRun", fallback: "Last run")
  /// Last run message with time
  internal static func lastRunTime(_ p1: Any) -> String {
    return L10n.tr("Localizable", "lastRunTime", String(describing: p1), fallback: "Last ran %@")
  }
  /// Session Client Last Seen Section Label
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
  /// Represents the light theme setting
  internal static let light = L10n.tr("Localizable", "light", fallback: "Light")
  /// Liked Items
  internal static let likedItems = L10n.tr("Localizable", "likedItems", fallback: "Liked Items")
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
  /// Settings View - Logs
  internal static let logs = L10n.tr("Localizable", "logs", fallback: "Logs")
  /// Access the Jellyfin server logs for troubleshooting and monitoring purposes.
  internal static let logsDescription = L10n.tr("Localizable", "logsDescription", fallback: "Access the Jellyfin server logs for troubleshooting and monitoring purposes.")
  /// Option to set the maximum bitrate for playback
  internal static let maximumBitrate = L10n.tr("Localizable", "maximumBitrate", fallback: "Maximum Bitrate")
  /// Playback May Fail
  internal static let mayResultInPlaybackFailure = L10n.tr("Localizable", "mayResultInPlaybackFailure", fallback: "This setting may result in media failing to start playback")
  /// Media
  internal static let media = L10n.tr("Localizable", "media", fallback: "Media")
  /// Menu Buttons
  internal static let menuButtons = L10n.tr("Localizable", "menuButtons", fallback: "Menu Buttons")
  /// The play method (e.g., Direct Play, Transcoding)
  internal static let method = L10n.tr("Localizable", "method", fallback: "Method")
  /// Minutes
  internal static let minutes = L10n.tr("Localizable", "minutes", fallback: "Minutes")
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
  /// Never
  internal static let never = L10n.tr("Localizable", "never", fallback: "Never")
  /// Message shown when a task has never run
  internal static let neverRun = L10n.tr("Localizable", "neverRun", fallback: "Never run")
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
  /// Settings Description for the day limit in Next Up
  internal static let nextUpDays = L10n.tr("Localizable", "nextUpDays", fallback: "Days in Next Up")
  /// Description for how the nextUpDays setting works
  internal static let nextUpDaysDescription = L10n.tr("Localizable", "nextUpDaysDescription", fallback: "Set the maximum amount of days a show should stay in the 'Next Up' list without watching it.")
  /// Settings Description for enabling rewatching in Next Up
  internal static let nextUpRewatch = L10n.tr("Localizable", "nextUpRewatch", fallback: "Rewatching in Next Up")
  /// No
  internal static let no = L10n.tr("Localizable", "no", fallback: "No")
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
  /// No runtime limit
  internal static let noRuntimeLimit = L10n.tr("Localizable", "noRuntimeLimit", fallback: "No runtime limit")
  /// No active session available
  internal static let noSession = L10n.tr("Localizable", "noSession", fallback: "No session")
  /// N/A
  internal static let notAvailableSlash = L10n.tr("Localizable", "notAvailableSlash", fallback: "N/A")
  /// Type: %@ not implemented yet :(
  internal static func notImplementedYetWithType(_ p1: Any) -> String {
    return L10n.tr("Localizable", "notImplementedYetWithType", String(describing: p1), fallback: "Type: %@ not implemented yet :(")
  }
  /// No title
  internal static let noTitle = L10n.tr("Localizable", "noTitle", fallback: "No title")
  /// Video Player Settings View - Offset
  internal static let offset = L10n.tr("Localizable", "offset", fallback: "Offset")
  /// OK
  internal static let ok = L10n.tr("Localizable", "ok", fallback: "OK")
  /// On application startup
  internal static let onApplicationStartup = L10n.tr("Localizable", "onApplicationStartup", fallback: "On application startup")
  /// 1 user
  internal static let oneUser = L10n.tr("Localizable", "oneUser", fallback: "1 user")
  /// Indicates that something is Online
  internal static let online = L10n.tr("Localizable", "online", fallback: "Online")
  /// On Now
  internal static let onNow = L10n.tr("Localizable", "onNow", fallback: "On Now")
  /// Operating System
  internal static let operatingSystem = L10n.tr("Localizable", "operatingSystem", fallback: "Operating System")
  /// Options
  internal static let options = L10n.tr("Localizable", "options", fallback: "Options")
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
  /// New passwords do not match
  internal static let passwordsDoNotMatch = L10n.tr("Localizable", "passwordsDoNotMatch", fallback: "New passwords do not match")
  /// Video Player Settings View - Pause on Background
  internal static let pauseOnBackground = L10n.tr("Localizable", "pauseOnBackground", fallback: "Pause on background")
  /// People
  internal static let people = L10n.tr("Localizable", "people", fallback: "People")
  /// Play
  internal static let play = L10n.tr("Localizable", "play", fallback: "Play")
  /// Play / Pause
  internal static let playAndPause = L10n.tr("Localizable", "playAndPause", fallback: "Play / Pause")
  /// Video Player Settings View - Playback Header
  internal static let playback = L10n.tr("Localizable", "playback", fallback: "Playback")
  /// Playback Buttons
  internal static let playbackButtons = L10n.tr("Localizable", "playbackButtons", fallback: "Playback Buttons")
  /// Section for Playback Quality Settings
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
  /// Video Player Settings View - Play on Active
  internal static let playOnActive = L10n.tr("Localizable", "playOnActive", fallback: "Play on active")
  /// Play Previous Item
  internal static let playPreviousItem = L10n.tr("Localizable", "playPreviousItem", fallback: "Play Previous Item")
  /// Customize Server View - Posters
  internal static let posters = L10n.tr("Localizable", "posters", fallback: "Posters")
  /// Present
  internal static let present = L10n.tr("Localizable", "present", fallback: "Present")
  /// Press Down for Menu
  internal static let pressDownForMenu = L10n.tr("Localizable", "pressDownForMenu", fallback: "Press Down for Menu")
  /// Previous Item
  internal static let previousItem = L10n.tr("Localizable", "previousItem", fallback: "Previous Item")
  /// Primary
  internal static let primary = L10n.tr("Localizable", "primary", fallback: "Primary")
  /// PlaybackCompatibility Profile Sections
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
  /// Customize Server View - Random Image
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
  /// TranscodeReason - Reference Frames Not Supported
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
  /// Remove All
  internal static let removeAll = L10n.tr("Localizable", "removeAll", fallback: "Remove All")
  /// Remove All Servers
  internal static let removeAllServers = L10n.tr("Localizable", "removeAllServers", fallback: "Remove All Servers")
  /// Remove All Users
  internal static let removeAllUsers = L10n.tr("Localizable", "removeAllUsers", fallback: "Remove All Users")
  /// Remove From Resume
  internal static let removeFromResume = L10n.tr("Localizable", "removeFromResume", fallback: "Remove From Resume")
  /// PlayMethod - Remux
  internal static let remux = L10n.tr("Localizable", "remux", fallback: "Remux")
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
  /// Restart Server Label
  internal static let restartServer = L10n.tr("Localizable", "restartServer", fallback: "Restart Server")
  /// Restart Warning Label
  internal static let restartWarning = L10n.tr("Localizable", "restartWarning", fallback: "Are you sure you want to restart the server?")
  /// Video Player Settings View - Resume
  internal static let resume = L10n.tr("Localizable", "resume", fallback: "Resume")
  /// Resume 5 Second Offset
  internal static let resume5SecondOffset = L10n.tr("Localizable", "resume5SecondOffset", fallback: "Resume 5 Second Offset")
  /// Resume Offset
  internal static let resumeOffset = L10n.tr("Localizable", "resumeOffset", fallback: "Resume Offset")
  /// Video Player Settings View - Resume Offset Description
  internal static let resumeOffsetDescription = L10n.tr("Localizable", "resumeOffsetDescription", fallback: "Resume content seconds before the recorded resume time")
  /// Video Player Settings View - Resume Offset Title
  internal static let resumeOffsetTitle = L10n.tr("Localizable", "resumeOffsetTitle", fallback: "Resume Offset")
  /// Retrieving media information
  internal static let retrievingMediaInformation = L10n.tr("Localizable", "retrievingMediaInformation", fallback: "Retrieving media information")
  /// Retry
  internal static let retry = L10n.tr("Localizable", "retry", fallback: "Retry")
  /// Right
  internal static let `right` = L10n.tr("Localizable", "right", fallback: "Right")
  /// Role
  internal static let role = L10n.tr("Localizable", "role", fallback: "Role")
  /// Button label to run a task
  internal static let run = L10n.tr("Localizable", "run", fallback: "Run")
  /// Status label for when a task is running
  internal static let running = L10n.tr("Localizable", "running", fallback: "Running...")
  /// Runtime
  internal static let runtime = L10n.tr("Localizable", "runtime", fallback: "Runtime")
  /// Save
  internal static let save = L10n.tr("Localizable", "save", fallback: "Save")
  /// Administration Dashboard Scan All Libraries Button
  internal static let scanAllLibraries = L10n.tr("Localizable", "scanAllLibraries", fallback: "Scan All Libraries")
  /// Administration Dashboard Scheduled Tasks
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
  /// TranscodeReason - Secondary Audio Not Supported
  internal static let secondaryAudioNotSupported = L10n.tr("Localizable", "secondaryAudioNotSupported", fallback: "Secondary audio is not supported")
  /// See All
  internal static let seeAll = L10n.tr("Localizable", "seeAll", fallback: "See All")
  /// Seek Slide Gesture Enabled
  internal static let seekSlideGestureEnabled = L10n.tr("Localizable", "seekSlideGestureEnabled", fallback: "Seek Slide Gesture Enabled")
  /// See More
  internal static let seeMore = L10n.tr("Localizable", "seeMore", fallback: "See More")
  /// Select All
  internal static let selectAll = L10n.tr("Localizable", "selectAll", fallback: "Select All")
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
  /// Title for the server logs section
  internal static let serverLogs = L10n.tr("Localizable", "serverLogs", fallback: "Server Logs")
  /// Select Server View
  internal static let servers = L10n.tr("Localizable", "servers", fallback: "Servers")
  /// A new trigger was created for '%1$@'.
  internal static func serverTriggerCreated(_ p1: Any) -> String {
    return L10n.tr("Localizable", "serverTriggerCreated", String(describing: p1), fallback: "A new trigger was created for '%1$@'.")
  }
  /// The selected trigger was deleted from '%1$@'.
  internal static func serverTriggerDeleted(_ p1: Any) -> String {
    return L10n.tr("Localizable", "serverTriggerDeleted", String(describing: p1), fallback: "The selected trigger was deleted from '%1$@'.")
  }
  /// Server URL
  internal static let serverURL = L10n.tr("Localizable", "serverURL", fallback: "Server URL")
  /// The title for the session view
  internal static let session = L10n.tr("Localizable", "session", fallback: "Session")
  /// Settings
  internal static let settings = L10n.tr("Localizable", "settings", fallback: "Settings")
  /// Show Cast & Crew
  internal static let showCastAndCrew = L10n.tr("Localizable", "showCastAndCrew", fallback: "Show Cast & Crew")
  /// Show Chapters Info In Bottom Overlay
  internal static let showChaptersInfoInBottomOverlay = L10n.tr("Localizable", "showChaptersInfoInBottomOverlay", fallback: "Show Chapters Info In Bottom Overlay")
  /// Indicators View - Show Favorited
  internal static let showFavorited = L10n.tr("Localizable", "showFavorited", fallback: "Show Favorited")
  /// Customize Server View - Show Favorites
  internal static let showFavorites = L10n.tr("Localizable", "showFavorites", fallback: "Show Favorites")
  /// Flatten Library Items
  internal static let showFlattenView = L10n.tr("Localizable", "showFlattenView", fallback: "Flatten Library Items")
  /// Show Missing Episodes
  internal static let showMissingEpisodes = L10n.tr("Localizable", "showMissingEpisodes", fallback: "Show Missing Episodes")
  /// Show Missing Seasons
  internal static let showMissingSeasons = L10n.tr("Localizable", "showMissingSeasons", fallback: "Show Missing Seasons")
  /// Show Poster Labels
  internal static let showPosterLabels = L10n.tr("Localizable", "showPosterLabels", fallback: "Show Poster Labels")
  /// Indicators View - Show Progress
  internal static let showProgress = L10n.tr("Localizable", "showProgress", fallback: "Show Progress")
  /// Customize Server View - Show Recently Added
  internal static let showRecentlyAdded = L10n.tr("Localizable", "showRecentlyAdded", fallback: "Show Recently Added")
  /// Indicators View - Show Unwatched
  internal static let showUnwatched = L10n.tr("Localizable", "showUnwatched", fallback: "Show Unwatched")
  /// Indicators View - Show Watched
  internal static let showWatched = L10n.tr("Localizable", "showWatched", fallback: "Show Watched")
  /// Shutdown Server Label
  internal static let shutdownServer = L10n.tr("Localizable", "shutdownServer", fallback: "Shutdown Server")
  /// Shutdown Warning Label
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
  /// Status
  internal static let status = L10n.tr("Localizable", "status", fallback: "Status")
  /// Button label to stop a task
  internal static let stop = L10n.tr("Localizable", "stop", fallback: "Stop")
  /// Session Streaming Clients
  internal static let streams = L10n.tr("Localizable", "streams", fallback: "Streams")
  /// STUDIO
  internal static let studio = L10n.tr("Localizable", "studio", fallback: "STUDIO")
  /// Studios
  internal static let studios = L10n.tr("Localizable", "studios", fallback: "Studios")
  /// Subtitle
  internal static let subtitle = L10n.tr("Localizable", "subtitle", fallback: "Subtitle")
  /// TranscodeReason - Subtitle Codec Not Supported
  internal static let subtitleCodecNotSupported = L10n.tr("Localizable", "subtitleCodecNotSupported", fallback: "The subtitle codec is not supported")
  /// Subtitle Color
  internal static let subtitleColor = L10n.tr("Localizable", "subtitleColor", fallback: "Subtitle Color")
  /// Subtitle Font
  internal static let subtitleFont = L10n.tr("Localizable", "subtitleFont", fallback: "Subtitle Font")
  /// Subtitle Offset
  internal static let subtitleOffset = L10n.tr("Localizable", "subtitleOffset", fallback: "Subtitle Offset")
  /// Subtitles
  internal static let subtitles = L10n.tr("Localizable", "subtitles", fallback: "Subtitles")
  /// Video Player Settings View - Disclaimer
  internal static let subtitlesDisclaimer = L10n.tr("Localizable", "subtitlesDisclaimer", fallback: "Settings only affect some subtitle types")
  /// Subtitle Size
  internal static let subtitleSize = L10n.tr("Localizable", "subtitleSize", fallback: "Subtitle Size")
  /// Success
  internal static let success = L10n.tr("Localizable", "success", fallback: "Success")
  /// Suggestions
  internal static let suggestions = L10n.tr("Localizable", "suggestions", fallback: "Suggestions")
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
  /// Represents the system theme setting
  internal static let system = L10n.tr("Localizable", "system", fallback: "System")
  /// System Control Gestures Enabled
  internal static let systemControlGesturesEnabled = L10n.tr("Localizable", "systemControlGesturesEnabled", fallback: "System Control Gestures Enabled")
  /// Tags
  internal static let tags = L10n.tr("Localizable", "tags", fallback: "Tags")
  /// The navigation title for the task view
  internal static let task = L10n.tr("Localizable", "task", fallback: "Task")
  /// Status message for an aborted task
  internal static let taskAborted = L10n.tr("Localizable", "taskAborted", fallback: "Aborted")
  /// Status message for a cancelled task
  internal static let taskCancelled = L10n.tr("Localizable", "taskCancelled", fallback: "Cancelled")
  /// Status message for a completed task
  internal static let taskCompleted = L10n.tr("Localizable", "taskCompleted", fallback: "Completed")
  /// Status message for a failed task
  internal static let taskFailed = L10n.tr("Localizable", "taskFailed", fallback: "Failed")
  /// Title for the tasks section
  internal static let tasks = L10n.tr("Localizable", "tasks", fallback: "Tasks")
  /// Description for the tasks section
  internal static let tasksDescription = L10n.tr("Localizable", "tasksDescription", fallback: "Tasks are operations that are scheduled to run periodically or can be triggered manually.")
  /// Sets the duration (in minutes) in between task triggers.
  internal static let taskTriggerInterval = L10n.tr("Localizable", "taskTriggerInterval", fallback: "Sets the duration (in minutes) in between task triggers.")
  /// Sets the maximum runtime (in hours) for this task trigger.
  internal static let taskTriggerTimeLimit = L10n.tr("Localizable", "taskTriggerTimeLimit", fallback: "Sets the maximum runtime (in hours) for this task trigger.")
  /// Option to set the test size for bitrate testing
  internal static let testSize = L10n.tr("Localizable", "testSize", fallback: "Test Size")
  /// Time
  internal static let time = L10n.tr("Localizable", "time", fallback: "Time")
  /// Time Limit
  internal static let timeLimit = L10n.tr("Localizable", "timeLimit", fallback: "Time Limit")
  /// Time limit: %1$@
  internal static func timeLimitLabelWithValue(_ p1: Any) -> String {
    return L10n.tr("Localizable", "timeLimitLabelWithValue", String(describing: p1), fallback: "Time limit: %1$@")
  }
  /// Time Limit (%@)
  internal static func timeLimitWithUnit(_ p1: Any) -> String {
    return L10n.tr("Localizable", "timeLimitWithUnit", String(describing: p1), fallback: "Time Limit (%@)")
  }
  /// Timestamp
  internal static let timestamp = L10n.tr("Localizable", "timestamp", fallback: "Timestamp")
  /// Timestamp Type
  internal static let timestampType = L10n.tr("Localizable", "timestampType", fallback: "Timestamp Type")
  /// Too Many Redirects
  internal static let tooManyRedirects = L10n.tr("Localizable", "tooManyRedirects", fallback: "Too Many Redirects")
  /// Trailing Value
  internal static let trailingValue = L10n.tr("Localizable", "trailingValue", fallback: "Trailing Value")
  /// PlayMethod - Transcode
  internal static let transcode = L10n.tr("Localizable", "transcode", fallback: "Transcode")
  /// Transcode Reason(s) Section Label
  internal static let transcodeReasons = L10n.tr("Localizable", "transcodeReasons", fallback: "Transcode Reason(s)")
  /// Transition
  internal static let transition = L10n.tr("Localizable", "transition", fallback: "Transition")
  /// Trigger already exists
  internal static let triggerAlreadyExists = L10n.tr("Localizable", "triggerAlreadyExists", fallback: "Trigger already exists")
  /// Triggers
  internal static let triggers = L10n.tr("Localizable", "triggers", fallback: "Triggers")
  /// Try again
  internal static let tryAgain = L10n.tr("Localizable", "tryAgain", fallback: "Try again")
  /// TV Shows
  internal static let tvShows = L10n.tr("Localizable", "tvShows", fallback: "TV Shows")
  /// Indicate a type
  internal static let type = L10n.tr("Localizable", "type", fallback: "Type")
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
  /// TranscodeReason - Unknown Audio Stream Info
  internal static let unknownAudioStreamInfo = L10n.tr("Localizable", "unknownAudioStreamInfo", fallback: "The audio stream information is unknown")
  /// Unknown Error
  internal static let unknownError = L10n.tr("Localizable", "unknownError", fallback: "Unknown Error")
  /// TranscodeReason - Unknown Video Stream Info
  internal static let unknownVideoStreamInfo = L10n.tr("Localizable", "unknownVideoStreamInfo", fallback: "The video stream information is unknown")
  /// Unplayed
  internal static let unplayed = L10n.tr("Localizable", "unplayed", fallback: "Unplayed")
  /// You have unsaved changes. Are you sure you want to discard them?
  internal static let unsavedChangesMessage = L10n.tr("Localizable", "unsavedChangesMessage", fallback: "You have unsaved changes. Are you sure you want to discard them?")
  /// URL
  internal static let url = L10n.tr("Localizable", "url", fallback: "URL")
  /// Override Transcoding Profile
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
  /// A username is required
  internal static let usernameRequired = L10n.tr("Localizable", "usernameRequired", fallback: "A username is required")
  /// Users
  internal static let users = L10n.tr("Localizable", "users", fallback: "Users")
  /// Version
  internal static let version = L10n.tr("Localizable", "version", fallback: "Version")
  /// Video
  internal static let video = L10n.tr("Localizable", "video", fallback: "Video")
  /// TranscodeReason - Video Bit Depth Not Supported
  internal static let videoBitDepthNotSupported = L10n.tr("Localizable", "videoBitDepthNotSupported", fallback: "The video bit depth is not supported")
  /// TranscodeReason - Video Bitrate Not Supported
  internal static let videoBitrateNotSupported = L10n.tr("Localizable", "videoBitrateNotSupported", fallback: "The video bitrate is not supported")
  /// TranscodeReason - Video Codec Not Supported
  internal static let videoCodecNotSupported = L10n.tr("Localizable", "videoCodecNotSupported", fallback: "The video codec is not supported")
  /// TranscodeReason - Video Framerate Not Supported
  internal static let videoFramerateNotSupported = L10n.tr("Localizable", "videoFramerateNotSupported", fallback: "The video framerate is not supported")
  /// TranscodeReason - Video Level Not Supported
  internal static let videoLevelNotSupported = L10n.tr("Localizable", "videoLevelNotSupported", fallback: "The video level is not supported")
  /// Settings View - Video Player
  internal static let videoPlayer = L10n.tr("Localizable", "videoPlayer", fallback: "Video Player")
  /// Video Player Type
  internal static let videoPlayerType = L10n.tr("Localizable", "videoPlayerType", fallback: "Video Player Type")
  /// TranscodeReason - Video Profile Not Supported
  internal static let videoProfileNotSupported = L10n.tr("Localizable", "videoProfileNotSupported", fallback: "The video profile is not supported")
  /// TranscodeReason - Video Range Type Not Supported
  internal static let videoRangeTypeNotSupported = L10n.tr("Localizable", "videoRangeTypeNotSupported", fallback: "The video range type is not supported")
  /// TranscodeReason - Video Resolution Not Supported
  internal static let videoResolutionNotSupported = L10n.tr("Localizable", "videoResolutionNotSupported", fallback: "The video resolution is not supported")
  /// Weekly
  internal static let weekly = L10n.tr("Localizable", "weekly", fallback: "Weekly")
  /// Who's watching?
  internal static let whosWatching = L10n.tr("Localizable", "WhosWatching", fallback: "Who's watching?")
  /// WIP
  internal static let wip = L10n.tr("Localizable", "wip", fallback: "WIP")
  /// Yellow
  internal static let yellow = L10n.tr("Localizable", "yellow", fallback: "Yellow")
  /// Yes
  internal static let yes = L10n.tr("Localizable", "yes", fallback: "Yes")
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
