// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Label to denote the section about a media item
  internal static let about = L10n.tr("Localizable", "about", fallback: "About")
  /// Label for accent color selection
  internal static let accentColor = L10n.tr("Localizable", "accentColor", fallback: "Accent Color")
  /// Label explaining a restart may be required
  internal static let accentColorDescription = L10n.tr("Localizable", "accentColorDescription", fallback: "Some views may need an app restart to update.")
  /// Represents the Accessibility section label
  internal static let accessibility = L10n.tr("Localizable", "accessibility", fallback: "Accessibility")
  /// Represents the label used to offer the user the ability to designate an additional URL for an existing Jellyfin Server
  internal static let addURL = L10n.tr("Localizable", "addURL", fallback: "Add URL")
  /// Represents the Advanced section label
  internal static let advanced = L10n.tr("Localizable", "advanced", fallback: "Advanced")
  /// Label indicating a show airs on s specific day of the week
  internal static func airWithDate(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "airWithDate", p1, fallback: "Airs %s")
  }
  /// Section Label for the Media View
  internal static let allMedia = L10n.tr("Localizable", "allMedia", fallback: "All Media")
  /// Represents the Appearance setting label
  internal static let appearance = L10n.tr("Localizable", "appearance", fallback: "Appearance")
  /// Section Header Label for changing the Swiftfin App Icon
  internal static let appIcon = L10n.tr("Localizable", "appIcon", fallback: "App Icon")
  /// Apply/Save the current values on the screen/form
  internal static let apply = L10n.tr("Localizable", "apply", fallback: "Apply")
  /// Option for aspect fill display mode
  internal static let aspectFill = L10n.tr("Localizable", "aspectFill", fallback: "Aspect Fill")
  /// Overlay Label for Selecting Audio Information/Settings
  internal static let audio = L10n.tr("Localizable", "audio", fallback: "Audio")
  /// Section Label for Audio, Captions/Subtitles configuration on the Video Playback Overlay
  internal static let audioAndCaptions = L10n.tr("Localizable", "audioAndCaptions", fallback: "Audio & Captions")
  /// Label for audio offset settings
  internal static let audioOffset = L10n.tr("Localizable", "audioOffset", fallback: "Audio Offset")
  /// Section label on the video player overlay to select the audio track for playback
  internal static let audioTrack = L10n.tr("Localizable", "audioTrack", fallback: "Audio Track")
  /// Represents the final step in the Quick Connect Authentication process using Swiftifn to Authorize another device
  internal static let authorize = L10n.tr("Localizable", "authorize", fallback: "Authorize")
  /// Option to enable auto play
  internal static let autoPlay = L10n.tr("Localizable", "autoPlay", fallback: "Auto Play")
  /// Go back to the previous screen/form
  internal static let back = L10n.tr("Localizable", "back", fallback: "Back")
  /// Label for bar buttons settings
  internal static let barButtons = L10n.tr("Localizable", "barButtons", fallback: "Bar Buttons")
  /// Option for automatic bitrate selection
  internal static let bitrateAuto = L10n.tr("Localizable", "bitrateAuto", fallback: "Auto")
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
  /// Description for bitrate test duration indicating larger tests provide more accurate bitrates but may delay playback
  internal static let bitrateTestDescription = L10n.tr("Localizable", "bitrateTestDescription", fallback: "Larger tests result in a more accurate bitrate but may delay playback")
  /// Represents the label for all Jellyfin Icons that are Blue regardless of Backgound/Color Invert
  internal static let blue = L10n.tr("Localizable", "blue", fallback: "Blue")
  /// Section of the Jellyfin/System screen directing users to the Swiftfin GitHub for Issue Tracking
  internal static let bugsAndFeatures = L10n.tr("Localizable", "bugsAndFeatures", fallback: "Bugs and Features")
  /// Label for buttons section
  internal static let buttons = L10n.tr("Localizable", "buttons", fallback: "Buttons")
  /// Stop the current operation or reset the screen/form
  internal static let cancel = L10n.tr("Localizable", "cancel", fallback: "Cancel")
  /// Label for cast and crew information
  internal static let castAndCrew = L10n.tr("Localizable", "castAndCrew", fallback: "Cast & Crew")
  /// Represents the label for the button that takes the user to the Server selection screen
  internal static let changeServer = L10n.tr("Localizable", "changeServer", fallback: "Change Server")
  /// Represents the the Library Labels for Live TV Channels
  internal static let channels = L10n.tr("Localizable", "channels", fallback: "Channels")
  /// Label for chapters section
  internal static let chapters = L10n.tr("Localizable", "chapters", fallback: "Chapters")
  /// Label for chapter slider
  internal static let chapterSlider = L10n.tr("Localizable", "chapterSlider", fallback: "Chapter Slider")
  /// Label for cinematic view
  internal static let cinematic = L10n.tr("Localizable", "cinematic", fallback: "Cinematic")
  /// Label for cinematic views
  internal static let cinematicViews = L10n.tr("Localizable", "cinematicViews", fallback: "Cinematic Views")
  /// Leave/close the current menu
  internal static let close = L10n.tr("Localizable", "close", fallback: "Close")
  /// Label for indicating Closed Captions or Subtitles for a media item
  internal static let closedCaptions = L10n.tr("Localizable", "closedCaptions", fallback: "Closed Captions")
  /// Represents the the Library Labels for Collections/Boxsets
  internal static let collections = L10n.tr("Localizable", "collections", fallback: "Collections")
  /// Label for color selection
  internal static let color = L10n.tr("Localizable", "color", fallback: "Color")
  /// Setting for Compact Text spacing as opposed to Normal Spacing
  internal static let compact = L10n.tr("Localizable", "compact", fallback: "Compact")
  /// Option for compact logo view
  internal static let compactLogo = L10n.tr("Localizable", "compactLogo", fallback: "Compact Logo")
  /// Option for compact poster view
  internal static let compactPoster = L10n.tr("Localizable", "compactPoster", fallback: "Compact Poster")
  /// tvOS Setting whether going back on the remote should close Swiftfin or if it should provide a confirmation first
  internal static let confirmClose = L10n.tr("Localizable", "confirmClose", fallback: "Confirm Close")
  /// Represents the Connect Button label for the Server Details provided
  internal static let connect = L10n.tr("Localizable", "connect", fallback: "Connect")
  /// Represents the first Connect to Server label on a new installation
  internal static let connectToJellyfinServer = L10n.tr("Localizable", "connectToJellyfinServer", fallback: "Connect to a Jellyfin server")
  /// Represents the first Connect to Server label on a new installation
  internal static let connectToJellyfinServerStart = L10n.tr("Localizable", "connectToJellyfinServerStart", fallback: "Connect to a Jellyfin server to get started")
  /// Represents the Connect Button label for the Server Details provided
  internal static let connectToServer = L10n.tr("Localizable", "connectToServer", fallback: "Connect to Server")
  /// Proceed or continue to the next screen as a proceed opposed to an agreement
  internal static let `continue` = L10n.tr("Localizable", "continue", fallback: "Continue")
  /// Represents the Home View section for items that are in-progress files
  internal static let continueWatching = L10n.tr("Localizable", "continueWatching", fallback: "Continue Watching")
  /// Label for current item
  internal static let current = L10n.tr("Localizable", "current", fallback: "Current")
  /// Label in the overlay to indicate the current time for the watched content
  internal static let currentPosition = L10n.tr("Localizable", "currentPosition", fallback: "Current Position")
  /// Button label to customize settings
  internal static let customize = L10n.tr("Localizable", "customize", fallback: "Customize")
  /// Represents the dark theme setting
  internal static let dark = L10n.tr("Localizable", "dark", fallback: "Dark")
  /// Section Title for Media Stream Info Views for Stream Delivery Properties
  internal static let delivery = L10n.tr("Localizable", "delivery", fallback: "Delivery")
  /// Feature/Setting is inactive
  internal static let disabled = L10n.tr("Localizable", "disabled", fallback: "Disabled")
  /// Represents the section label for Jellyfin Server(s) that were found during Jellyfin Server Discovery
  internal static let discoveredServers = L10n.tr("Localizable", "discoveredServers", fallback: "Discovered Servers")
  /// Dismiss a message or popup
  internal static let dismiss = L10n.tr("Localizable", "dismiss", fallback: "Dismiss")
  /// Represents the the Filter Labels for Library/Search Sorting
  internal static let displayOrder = L10n.tr("Localizable", "displayOrder", fallback: "Display order")
  /// Section Label for the Media's Downloaded Media Section
  internal static let downloads = L10n.tr("Localizable", "downloads", fallback: "Downloads")
  /// Button label to edit jump lengths
  internal static let editJumpLengths = L10n.tr("Localizable", "editJumpLengths", fallback: "Edit Jump Lengths")
  /// Feature/Setting is active
  internal static let enabled = L10n.tr("Localizable", "enabled", fallback: "Enabled")
  /// Label for episode landscape poster
  internal static let episodeLandscapePoster = L10n.tr("Localizable", "episodeLandscapePoster", fallback: "Episode Landscape Poster")
  /// Label for episode number
  internal static func episodeNumber(_ p1: Any) -> String {
    return L10n.tr("Localizable", "episodeNumber", String(describing: p1), fallback: "Episode %1$@")
  }
  /// Label used to designate an Episode contained within a Show Library
  internal static let episodes = L10n.tr("Localizable", "episodes", fallback: "Episodes")
  /// Generic error for handling uncaught & unexpected interactions
  internal static let error = L10n.tr("Localizable", "error", fallback: "Error")
  /// Represents a Settings Section for settings that are not fully ready
  internal static let experimental = L10n.tr("Localizable", "experimental", fallback: "Experimental")
  /// Represents the the Favorited Labels for Library/Search Filters
  internal static let favorited = L10n.tr("Localizable", "favorited", fallback: "Favorited")
  /// Section Label for the Media's Favorite Section
  internal static let favorites = L10n.tr("Localizable", "favorites", fallback: "Favorites")
  /// A Media/Subtitle object as a File on a Server System or local device
  internal static let file = L10n.tr("Localizable", "file", fallback: "File")
  /// Represents the the Filter Labels for Library/Search Filters
  internal static let filters = L10n.tr("Localizable", "filters", fallback: "Filters")
  /// Represents the the Filter Labels for Library/Search Filtering based on Item Genre(s)
  internal static let genres = L10n.tr("Localizable", "genres", fallback: "Genres")
  /// Section header for all Playback Gestures settings
  internal static let gestures = L10n.tr("Localizable", "gestures", fallback: "Gestures")
  /// Represents the label for all Jellyfin Icons that are Green regardless of Backgound/Color Invert
  internal static let green = L10n.tr("Localizable", "green", fallback: "Green")
  /// Label for the Grid Feature that formats the Library Items in a Grid
  internal static let grid = L10n.tr("Localizable", "grid", fallback: "Grid")
  /// Go back to the Home screen/form
  internal static let home = L10n.tr("Localizable", "home", fallback: "Home")
  /// Label for indicators settings
  internal static let indicators = L10n.tr("Localizable", "indicators", fallback: "Indicators")
  /// Label for information section
  internal static let information = L10n.tr("Localizable", "information", fallback: "Information")
  /// App Icons that are Colored with the Selected Color but have a Black Background
  internal static let invertedDark = L10n.tr("Localizable", "invertedDark", fallback: "Inverted Dark")
  /// App Icons that are Colored with the Selected Color but have a White Background
  internal static let invertedLight = L10n.tr("Localizable", "invertedLight", fallback: "Inverted Light")
  /// Generic term for Movies/Episodes/Shows... etc
  internal static let items = L10n.tr("Localizable", "items", fallback: "Items")
  /// Label for jump button
  internal static let jump = L10n.tr("Localizable", "jump", fallback: "Jump")
  /// Overlay Label for jumping backwards in the media based on the Jump configuration in Playback Settings
  internal static let jumpBackward = L10n.tr("Localizable", "jumpBackward", fallback: "Jump Backward")
  /// Section Title for setting how far backwards the jump backwards button goes
  internal static let jumpBackwardLength = L10n.tr("Localizable", "jumpBackwardLength", fallback: "Jump Backward Length")
  /// Overlay Label for jumping forward in the media based on the Jump configuration in Playback Settings
  internal static let jumpForward = L10n.tr("Localizable", "jumpForward", fallback: "Jump Forward")
  /// Section Title for setting how far forward the jump forward button goes
  internal static let jumpForwardLength = L10n.tr("Localizable", "jumpForwardLength", fallback: "Jump Forward Length")
  /// Message Describing if gesture for jumping forward/backward is enabled
  internal static let jumpGesturesEnabled = L10n.tr("Localizable", "jumpGesturesEnabled", fallback: "Jump Gestures Enabled")
  /// Label for jump length in seconds
  internal static func jumpLengthSeconds(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "jumpLengthSeconds", p1, fallback: "%s seconds")
  }
  /// Represents the the Library Labels for Live TV Programs/Shows that are Kids Content
  internal static let kids = L10n.tr("Localizable", "kids", fallback: "Kids")
  /// Option for a larger than regular item type
  internal static let larger = L10n.tr("Localizable", "larger", fallback: "Larger")
  /// Option for the largest item type
  internal static let largest = L10n.tr("Localizable", "largest", fallback: "Largest")
  /// Represents the Home View section for All media items that are new for each Media Type
  internal static func latestWithString(_ p1: Any) -> String {
    return L10n.tr("Localizable", "latestWithString", String(describing: p1), fallback: "Latest %@")
  }
  /// The Letter Picker Bar will be on the Left/Leading side of the Library
  internal static let `left` = L10n.tr("Localizable", "left", fallback: "Left")
  /// Represents the Letter Picker Enabled section label
  internal static let letterPicker = L10n.tr("Localizable", "letterPicker", fallback: "Letter Picker")
  /// Label used to designate a Library
  internal static let library = L10n.tr("Localizable", "library", fallback: "Library")
  /// Represents the light theme setting
  internal static let light = L10n.tr("Localizable", "light", fallback: "Light")
  /// Label for the List Feature that formats the Library Items in a List
  internal static let list = L10n.tr("Localizable", "list", fallback: "List")
  /// Section Label for the Media's Live TV Section
  internal static let liveTV = L10n.tr("Localizable", "liveTV", fallback: "Live TV")
  /// View is loading data
  internal static let loading = L10n.tr("Localizable", "loading", fallback: "Loading")
  /// Represents the section label for local/LAN Jellyfin Server(s) that were found during Jellyfin Server Discovery
  internal static let localServers = L10n.tr("Localizable", "localServers", fallback: "Local Servers")
  /// Section Label for the logs generated by Swiftfin
  internal static let logs = L10n.tr("Localizable", "logs", fallback: "Logs")
  /// Option to set the maximum bitrate for playback
  internal static let maximumBitrate = L10n.tr("Localizable", "maximumBitrate", fallback: "Maximum Bitrate")
  /// Section Label for all Media Library Sections
  internal static let media = L10n.tr("Localizable", "media", fallback: "Media")
  /// Label for video player menu buttons
  internal static let menuButtons = L10n.tr("Localizable", "menuButtons", fallback: "Menu Buttons")
  /// Label indicating missing items
  internal static let missing = L10n.tr("Localizable", "missing", fallback: "Missing")
  /// Label for missing items section
  internal static let missingItems = L10n.tr("Localizable", "missingItems", fallback: "Missing Items")
  /// Represents the the Media Item section for Jellyfin recommendations
  internal static let moreLikeThis = L10n.tr("Localizable", "moreLikeThis", fallback: "More Like This")
  /// Represents the the Library Labels for Movie Media Types
  internal static let movies = L10n.tr("Localizable", "movies", fallback: "Movies")
  /// Label indicating something's name
  internal static let name = L10n.tr("Localizable", "name", fallback: "Name")
  /// Indicates that Swiftfin playback is using AVKit
  internal static let nativePlayer = L10n.tr("Localizable", "nativePlayer", fallback: "Native Player")
  /// Represents the the Library Labels for Live TV Programs/Shows that are News/Current Events Content
  internal static let news = L10n.tr("Localizable", "news", fallback: "News")
  /// Button label for the next item
  internal static let next = L10n.tr("Localizable", "next", fallback: "Next")
  /// Overlay Label for going to the next episode in a show
  internal static let nextItem = L10n.tr("Localizable", "nextItem", fallback: "Next Item")
  /// Represents the Home View section for Show items are in-progress Seasons
  internal static let nextUp = L10n.tr("Localizable", "nextUp", fallback: "Next Up")
  /// Represents the Media Casting Device selection when no Media Casting Devices were found
  internal static let noCastdevicesfound = L10n.tr("Localizable", "noCastdevicesfound", fallback: "No Cast devices found..")
  /// Label indicating no codec is available
  internal static let noCodec = L10n.tr("Localizable", "noCodec", fallback: "No Codec")
  /// Represents the label that will exist in place of an episode view if there are no episodes
  internal static let noEpisodesAvailable = L10n.tr("Localizable", "noEpisodesAvailable", fallback: "No episodes available")
  /// Message Label to designate that the Server Discovery process did not find any local/LAN Server(s)
  internal static let noLocalServersFound = L10n.tr("Localizable", "noLocalServersFound", fallback: "No local servers found")
  /// Label indicating none
  internal static let `none` = L10n.tr("Localizable", "none", fallback: "None")
  /// Label indicating no overview is available
  internal static let noOverviewAvailable = L10n.tr("Localizable", "noOverviewAvailable", fallback: "No overview available")
  /// Message indicating there are no public users
  internal static let noPublicUsers = L10n.tr("Localizable", "noPublicUsers", fallback: "No public Users")
  /// Used as a catch when the Library and/or Filtering results in no value content
  internal static let noResults = L10n.tr("Localizable", "noResults", fallback: "No results.")
  /// Setting for Normal Text spacing as opposed to Compact Spacing
  internal static let normal = L10n.tr("Localizable", "normal", fallback: "Normal")
  /// Label for not available
  internal static let notAvailableSlash = L10n.tr("Localizable", "notAvailableSlash", fallback: "N/A")
  /// Represents media types that are not currently implemented
  internal static func notImplementedYetWithType(_ p1: Any) -> String {
    return L10n.tr("Localizable", "notImplementedYetWithType", String(describing: p1), fallback: "Type: %@ not implemented yet :(")
  }
  /// Label indicating no title is available
  internal static let noTitle = L10n.tr("Localizable", "noTitle", fallback: "No title")
  /// Proceed with the current values on the screen/form
  internal static let ok = L10n.tr("Localizable", "ok", fallback: "Ok")
  /// Represents the the Library Labels for Live TV Programs/Shows that are on Now
  internal static let onNow = L10n.tr("Localizable", "onNow", fallback: "On Now")
  /// Section Label for OS running the current connected Jellyfin Server
  internal static let operatingSystem = L10n.tr("Localizable", "operatingSystem", fallback: "Operating System")
  /// Represents the label for all Jellyfin Icons that are Orange regardless of Backgound/Color Invert
  internal static let orange = L10n.tr("Localizable", "orange", fallback: "Orange")
  /// Button Label to indicate that this Filter Object sets the Library Order Ascending/Descending by the Sort Types
  internal static let order = L10n.tr("Localizable", "order", fallback: "Order")
  /// Represents the Letter Picker Orientation section label
  internal static let orientation = L10n.tr("Localizable", "orientation", fallback: "Orientation")
  /// Represents the the Library Labels for Other Media Types
  internal static let other = L10n.tr("Localizable", "other", fallback: "Other")
  /// Label for overview information
  internal static let overview = L10n.tr("Localizable", "overview", fallback: "Overview")
  /// Represents the section label for where a User Password needs to go. Also found in the User Settings to change/reset password
  internal static let password = L10n.tr("Localizable", "password", fallback: "Password")
  /// Option for pausing the Player when it's sent to the background
  internal static let pauseOnBackground = L10n.tr("Localizable", "pauseOnBackground", fallback: "Pause on background")
  /// Label for people section of the Search View
  internal static let people = L10n.tr("Localizable", "people", fallback: "People")
  /// Represents the Media Item button label to start a Media Item playback
  internal static let play = L10n.tr("Localizable", "play", fallback: "Play")
  /// Overlay Label for Playing/Pausing currently watched content
  internal static let playAndPause = L10n.tr("Localizable", "playAndPause", fallback: "Play / Pause")
  /// Represents the Playback section label
  internal static let playback = L10n.tr("Localizable", "playback", fallback: "Playback")
  /// Label for playback buttons
  internal static let playbackButtons = L10n.tr("Localizable", "playbackButtons", fallback: "Playback Buttons")
  /// Represents the Playback Settings section label
  internal static let playbackSettings = L10n.tr("Localizable", "playbackSettings", fallback: "Playback settings")
  /// Label for playback speed settings
  internal static let playbackSpeed = L10n.tr("Localizable", "playbackSpeed", fallback: "Playback Speed")
  /// Library Item has been watch by this user
  internal static let played = L10n.tr("Localizable", "played", fallback: "Played")
  /// Message Describing the current enabled status of the Player's Gesture Lock
  internal static let playerGesturesLockGestureEnabled = L10n.tr("Localizable", "playerGesturesLockGestureEnabled", fallback: "Player Gestures Lock Gesture Enabled")
  /// Option to play from the beginning
  internal static let playFromBeginning = L10n.tr("Localizable", "playFromBeginning", fallback: "Play From Beginning")
  /// Represents the Media Item button label to start the Media Item playback for a Collection of Items
  internal static let playNext = L10n.tr("Localizable", "playNext", fallback: "Play Next")
  /// Button label to play the next item
  internal static let playNextItem = L10n.tr("Localizable", "playNextItem", fallback: "Play Next Item")
  /// Option for resuming the Player when it's sent back to the foreground
  internal static let playOnActive = L10n.tr("Localizable", "playOnActive", fallback: "Play on active")
  /// Button label to play the previous item
  internal static let playPreviousItem = L10n.tr("Localizable", "playPreviousItem", fallback: "Play Previous Item")
  /// Label for Media Items posters
  internal static let posters = L10n.tr("Localizable", "posters", fallback: "Posters")
  /// Label for a show that is active until present
  internal static let present = L10n.tr("Localizable", "present", fallback: "Present")
  /// Label for press down for menu
  internal static let pressDownForMenu = L10n.tr("Localizable", "pressDownForMenu", fallback: "Press Down for Menu")
  /// Overlay Label for going back to previous episode in a show
  internal static let previousItem = L10n.tr("Localizable", "previousItem", fallback: "Previous Item")
  /// Represents the label for the default Jellyfin Icon for Swiftfin
  internal static let primary = L10n.tr("Localizable", "primary", fallback: "Primary")
  /// Represents the the Library Labels for Live TV Programs
  internal static let programs = L10n.tr("Localizable", "programs", fallback: "Programs")
  /// Label for playback progress
  internal static let progress = L10n.tr("Localizable", "progress", fallback: "Progress")
  /// Represents the section label for public users
  internal static let publicUsers = L10n.tr("Localizable", "publicUsers", fallback: "Public Users")
  /// Represents the Quick Connect Section title Label
  internal static let quickConnect = L10n.tr("Localizable", "quickConnect", fallback: "Quick Connect")
  /// Represents the Quick Connect Section title Label for where the Code is input
  internal static let quickConnectCode = L10n.tr("Localizable", "quickConnectCode", fallback: "Quick Connect code")
  /// Represents the Quick Connect message label when Quick Connect authorization for another device fails due to incorrect code
  internal static let quickConnectInvalidError = L10n.tr("Localizable", "quickConnectInvalidError", fallback: "Invalid Quick Connect code")
  /// Represents the Quick Connect message label when Quick Connect authorization for another device fails due to being disabled on Server
  internal static let quickConnectNotEnabled = L10n.tr("Localizable", "quickConnectNotEnabled", fallback: "Note: Quick Connect not enabled")
  /// Represents the Quick Connect message message for step 1 when adding an account to Swiftfin using Quick Connect from another device
  internal static let quickConnectStep1 = L10n.tr("Localizable", "quickConnectStep1", fallback: "1. Open the Jellyfin app on your phone or web browser and sign in with your account")
  /// Represents the Quick Connect message message for step 2 when adding an account to Swiftfin using Quick Connect from another device
  internal static let quickConnectStep2 = L10n.tr("Localizable", "quickConnectStep2", fallback: "2. Open the user menu and go to the Quick Connect page")
  /// Represents the Quick Connect message message for step 3 when adding an account to Swiftfin using Quick Connect from another device
  internal static let quickConnectStep3 = L10n.tr("Localizable", "quickConnectStep3", fallback: "3. Enter the following code:")
  /// Represents the Quick Connect message label when Quick Connect authorization for another device succeeds
  internal static let quickConnectSuccessMessage = L10n.tr("Localizable", "quickConnectSuccessMessage", fallback: "Authorizing Quick Connect successful. Please continue on your other device.")
  /// Label for the Random Feature that sends the users to a Random Library Item
  internal static let random = L10n.tr("Localizable", "random", fallback: "Random")
  /// Media Items will use a Random Image opposed to their Cover Image
  internal static let randomImage = L10n.tr("Localizable", "randomImage", fallback: "Random Image")
  /// Label for ratings section
  internal static let ratings = L10n.tr("Localizable", "ratings", fallback: "Ratings")
  /// Label for recently added items
  internal static let recentlyAdded = L10n.tr("Localizable", "recentlyAdded", fallback: "Recently Added")
  /// Label for recommended items
  internal static let recommended = L10n.tr("Localizable", "recommended", fallback: "Recommended")
  /// Represents the label for all Jellyfin Icons that are Red regardless of Backgound/Color Invert
  internal static let red = L10n.tr("Localizable", "red", fallback: "Red")
  /// Refresh the current view
  internal static let refresh = L10n.tr("Localizable", "refresh", fallback: "Refresh")
  /// Option for the a standard/regular item type
  internal static let regular = L10n.tr("Localizable", "regular", fallback: "Regular")
  /// Label indicating the released date
  internal static let released = L10n.tr("Localizable", "released", fallback: "Released")
  /// Reload the current view
  internal static let reload = L10n.tr("Localizable", "reload", fallback: "Reload")
  /// Label in the overlay to indicate time remaining in the watched content
  internal static let remainingTime = L10n.tr("Localizable", "remainingTime", fallback: "Remaining Time")
  /// Button label to remove an item
  internal static let remove = L10n.tr("Localizable", "remove", fallback: "Remove")
  /// Represents a label for a button to remove all Users & Servers in Swiftfin
  internal static let removeAllServers = L10n.tr("Localizable", "removeAllServers", fallback: "Remove All Servers")
  /// Represents a label for a button to remove all Users from a Jellyfin Server in Swiftfin
  internal static let removeAllUsers = L10n.tr("Localizable", "removeAllUsers", fallback: "Remove All Users")
  /// Option to remove from resume
  internal static let removeFromResume = L10n.tr("Localizable", "removeFromResume", fallback: "Remove From Resume")
  /// Section of the Jellyfin/System screen directing users to the Swiftfin GitHub for Issue Reporting
  internal static let reportIssue = L10n.tr("Localizable", "reportIssue", fallback: "Report an Issue")
  /// Section of the Jellyfin/System screen directing users to the Swiftfin GitHub for Feature Requesting
  internal static let requestFeature = L10n.tr("Localizable", "requestFeature", fallback: "Request a Feature")
  /// Reset the form/screen back to the default/previous values
  internal static let reset = L10n.tr("Localizable", "reset", fallback: "Reset")
  /// Message explaining
  internal static let resetAllSettings = L10n.tr("Localizable", "resetAllSettings", fallback: "Reset all settings back to defaults.")
  /// Section Label for Full App Settings Reset
  internal static let resetAppSettings = L10n.tr("Localizable", "resetAppSettings", fallback: "Reset App Settings")
  /// Section Label for User Settings Reset
  internal static let resetUserSettings = L10n.tr("Localizable", "resetUserSettings", fallback: "Reset User Settings")
  /// Option for a 5-second resume offset
  internal static let resume5SecondOffset = L10n.tr("Localizable", "resume5SecondOffset", fallback: "Resume 5 Second Offset")
  /// Label for resume offset settings
  internal static let resumeOffset = L10n.tr("Localizable", "resumeOffset", fallback: "Resume Offset")
  /// Description for resume offset settings
  internal static let resumeOffsetDescription = L10n.tr("Localizable", "resumeOffsetDescription", fallback: "Resume content seconds before the recorded resume time")
  /// Message indicating media information is being retrieved
  internal static let retrievingMediaInformation = L10n.tr("Localizable", "retrievingMediaInformation", fallback: "Retrieving media information")
  /// Retry an action typical after it failed the first time
  internal static let retry = L10n.tr("Localizable", "retry", fallback: "Retry")
  /// The Letter Picker Bar will be on the Right/Trailing side of the Library
  internal static let `right` = L10n.tr("Localizable", "right", fallback: "Right")
  /// Label for runtime information
  internal static let runtime = L10n.tr("Localizable", "runtime", fallback: "Runtime")
  /// Label for scrub current time
  internal static let scrubCurrentTime = L10n.tr("Localizable", "scrubCurrentTime", fallback: "Scrub Current Time")
  /// Represents the Section Label for the Search View
  internal static let search = L10n.tr("Localizable", "search", fallback: "Search")
  /// Represents the Search action designated as in-progress or an option on the view. Also used during Server Discovery
  internal static let searchDots = L10n.tr("Localizable", "searchDots", fallback: "Search…")
  /// Represents the the Library Labels for Show Media Types with a single Season
  internal static let season = L10n.tr("Localizable", "season", fallback: "Season")
  /// Represents the Media Item label to denote a Show's Season & Episode
  internal static func seasonAndEpisode(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "seasonAndEpisode", String(describing: p1), String(describing: p2), fallback: "S%1$@:E%2$@")
  }
  /// Represents the the Library Labels for Show Media Types with multiple Seasons
  internal static let seasons = L10n.tr("Localizable", "seasons", fallback: "Seasons")
  /// Expand a section to see all items
  internal static let seeAll = L10n.tr("Localizable", "seeAll", fallback: "See All")
  /// Message Describing the current enabled status of the Player's Gesture to Seek on the Timeline for currently playing content
  internal static let seekSlideGestureEnabled = L10n.tr("Localizable", "seekSlideGestureEnabled", fallback: "Seek Slide Gesture Enabled")
  /// Button label to see more content
  internal static let seeMore = L10n.tr("Localizable", "seeMore", fallback: "See More")
  /// Represents the Media Casting Device selection label
  internal static let selectCastDestination = L10n.tr("Localizable", "selectCastDestination", fallback: "Select Cast Destination")
  /// Represents the the Library Labels for Series / Shows Media Type
  internal static let series = L10n.tr("Localizable", "series", fallback: "Series")
  /// Label for series backdrop
  internal static let seriesBackdrop = L10n.tr("Localizable", "seriesBackdrop", fallback: "Series Backdrop")
  /// Generic term for the Active Jellyfin Server
  internal static let server = L10n.tr("Localizable", "server", fallback: "Server")
  /// Represents the section label for where a User Password needs to go. Also found in the User Settings to change/reset password
  internal static func serverAlreadyConnected(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "serverAlreadyConnected", p1, fallback: "Server %s is already connected")
  }
  /// Represents the label used to offer the user the ability to designate an additional URL for an existing Jellyfin Server
  internal static func serverAlreadyExistsPrompt(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "serverAlreadyExistsPrompt", p1, fallback: "Server %s already exists. Add new URL?")
  }
  /// Section Label for details about the current connected Jellyfin Server
  internal static let serverDetails = L10n.tr("Localizable", "serverDetails", fallback: "Server Details")
  /// Represents the label used to head the section where Server Information is configured for new devices or on tvOS to designate the Server information
  internal static let serverInformation = L10n.tr("Localizable", "serverInformation", fallback: "Server Information")
  /// Generic term for one or more Jellyfin Server
  internal static let servers = L10n.tr("Localizable", "servers", fallback: "Servers")
  /// Represents the label used to head the section where Server Information is configured for new devices or on tvOS to designate the Server information
  internal static let serverURL = L10n.tr("Localizable", "serverURL", fallback: "Server URL")
  /// Section Label for the Settings Screen
  internal static let settings = L10n.tr("Localizable", "settings", fallback: "Settings")
  /// Option to show cast and crew information
  internal static let showCastAndCrew = L10n.tr("Localizable", "showCastAndCrew", fallback: "Show Cast & Crew")
  /// Option to enable chapters info in the bottom overlay
  internal static let showChaptersInfoInBottomOverlay = L10n.tr("Localizable", "showChaptersInfoInBottomOverlay", fallback: "Show Chapters Info In Bottom Overlay")
  /// Option to flatten library items
  internal static let showFlattenView = L10n.tr("Localizable", "showFlattenView", fallback: "Flatten Library Items")
  /// Option to show missing episodes
  internal static let showMissingEpisodes = L10n.tr("Localizable", "showMissingEpisodes", fallback: "Show Missing Episodes")
  /// Option to show missing seasons
  internal static let showMissingSeasons = L10n.tr("Localizable", "showMissingSeasons", fallback: "Show Missing Seasons")
  /// Option to show poster labels
  internal static let showPosterLabels = L10n.tr("Localizable", "showPosterLabels", fallback: "Show Poster Labels")
  /// Button label that confirms the user information and attempts to sign them in
  internal static let signIn = L10n.tr("Localizable", "signIn", fallback: "Sign In")
  /// Message on first setup pointing the user to sign in
  internal static let signInGetStarted = L10n.tr("Localizable", "signInGetStarted", fallback: "Sign in to get started")
  /// Message indicating the server that the user is signing in to
  internal static func signInToServer(_ p1: UnsafePointer<CChar>) -> String {
    return L10n.tr("Localizable", "signInToServer", p1, fallback: "Sign In to %s")
  }
  /// Label for slider settings
  internal static let slider = L10n.tr("Localizable", "slider", fallback: "Slider")
  /// Label for slider color
  internal static let sliderColor = L10n.tr("Localizable", "sliderColor", fallback: "Slider Color")
  /// Label for slider type
  internal static let sliderType = L10n.tr("Localizable", "sliderType", fallback: "Slider Type")
  /// Option for a smaller than regular item type
  internal static let smaller = L10n.tr("Localizable", "smaller", fallback: "Smaller")
  /// Option for the smallest item type
  internal static let smallest = L10n.tr("Localizable", "smallest", fallback: "Smallest")
  /// Button Label to indicate that this Filter Object sets the Library Order by an Item/Filter
  internal static let sort = L10n.tr("Localizable", "sort", fallback: "Sort")
  /// Represents the the Filter Labels for Library/Search Sorting based on Item Attribute
  internal static let sortBy = L10n.tr("Localizable", "sortBy", fallback: "Sort by")
  /// Label for source code
  internal static let sourceCode = L10n.tr("Localizable", "sourceCode", fallback: "Source Code")
  /// Label for special features section
  internal static let specialFeatures = L10n.tr("Localizable", "specialFeatures", fallback: "Special Features")
  /// Represents the the Library Labels for Live TV Programs/Shows that are Sports Content
  internal static let sports = L10n.tr("Localizable", "sports", fallback: "Sports")
  /// Represents the the Filter Labels for Library/Search Filtering based on Item Studio
  internal static let studios = L10n.tr("Localizable", "studios", fallback: "Studios")
  /// Overlay Label for Selecting Subtitle/Caption Information/Settings
  internal static let subtitle = L10n.tr("Localizable", "subtitle", fallback: "Subtitle")
  /// Section Label to for a configuration to customize subtitle color
  internal static let subtitleColor = L10n.tr("Localizable", "subtitleColor", fallback: "Subtitle Color")
  /// Section Label to for a configuration to customize subtitle font
  internal static let subtitleFont = L10n.tr("Localizable", "subtitleFont", fallback: "Subtitle Font")
  /// Section Label to for a configuration to offset subtitles at playback
  internal static let subtitleOffset = L10n.tr("Localizable", "subtitleOffset", fallback: "Subtitle Offset")
  /// Label for subtitles settings/selection
  internal static let subtitles = L10n.tr("Localizable", "subtitles", fallback: "Subtitles")
  /// Section Label to for a configuration to customize subtitle size
  internal static let subtitleSize = L10n.tr("Localizable", "subtitleSize", fallback: "Subtitle Size")
  /// Represents the label used in the User Settings to change users and go to the Server Selection/Login page
  internal static let switchUser = L10n.tr("Localizable", "switchUser", fallback: "Switch User")
  /// Represents the system theme setting
  internal static let system = L10n.tr("Localizable", "system", fallback: "System")
  /// Message Describing the current enabled status of the Player's Gestures for System Contols like Volume/Brightness
  internal static let systemControlGesturesEnabled = L10n.tr("Localizable", "systemControlGesturesEnabled", fallback: "System Control Gestures Enabled")
  /// Represents the the Filter Labels for Library/Search Filtering based on Item Tag(s)
  internal static let tags = L10n.tr("Localizable", "tags", fallback: "Tags")
  /// Option to set the test sizes for bitrate testing
  internal static let testSize = L10n.tr("Localizable", "testSize", fallback: "Test Size")
  /// Label for timestamp settings
  internal static let timestamp = L10n.tr("Localizable", "timestamp", fallback: "Timestamp")
  /// Label for timestamp type
  internal static let timestampType = L10n.tr("Localizable", "timestampType", fallback: "Timestamp Type")
  /// Message indicating too many redirects
  internal static let tooManyRedirects = L10n.tr("Localizable", "tooManyRedirects", fallback: "Too Many Redirects")
  /// Label for trailing value
  internal static let trailingValue = L10n.tr("Localizable", "trailingValue", fallback: "Trailing Value")
  /// Label to denote the Transition Section
  internal static let transition = L10n.tr("Localizable", "transition", fallback: "Transition")
  /// Re-attempt to load a previously failed object
  internal static let tryAgain = L10n.tr("Localizable", "tryAgain", fallback: "Try again")
  /// Represents the the Library Labels for Show Media Types
  internal static let tvShows = L10n.tr("Localizable", "tvShows", fallback: "TV Shows")
  /// The Server Add/Sign in process has failed and this message is displayed
  internal static let unableToConnectServer = L10n.tr("Localizable", "unableToConnectServer", fallback: "Unable to connect to server")
  /// Message indicating the host could not be found
  internal static let unableToFindHost = L10n.tr("Localizable", "unableToFindHost", fallback: "Unable to find host")
  /// Label indicating a show that has not aired
  internal static let unaired = L10n.tr("Localizable", "unaired", fallback: "Unaired")
  /// Message indicating unauthorized access
  internal static let unauthorized = L10n.tr("Localizable", "unauthorized", fallback: "Unauthorized")
  /// Message indicating an unauthorized user
  internal static let unauthorizedUser = L10n.tr("Localizable", "unauthorizedUser", fallback: "Unauthorized user")
  /// Generic label for unknown objects
  internal static let unknown = L10n.tr("Localizable", "unknown", fallback: "Unknown")
  /// Generic error for handling uncaught & unexpected interactions
  internal static let unknownError = L10n.tr("Localizable", "unknownError", fallback: "Unknown Error")
  /// Library Item has not been watch by this user
  internal static let unplayed = L10n.tr("Localizable", "unplayed", fallback: "Unplayed")
  /// Label indicating the Jellyfin Server URL
  internal static let url = L10n.tr("Localizable", "url", fallback: "URL")
  /// Label for the setting to use the Primary Image for Media Items
  internal static let usePrimaryImage = L10n.tr("Localizable", "usePrimaryImage", fallback: "Use Primary Image")
  /// Label the message explainging the 'User Primary Image' setting
  internal static let usePrimaryImageDescription = L10n.tr("Localizable", "usePrimaryImageDescription", fallback: "Uses the primary image and hides the logo.")
  /// Label for user settings
  internal static let user = L10n.tr("Localizable", "user", fallback: "User")
  /// Represents the label used to head the section where a username needs to be provided to connect to a server
  internal static let username = L10n.tr("Localizable", "username", fallback: "Username")
  /// Label for the server version field
  internal static let version = L10n.tr("Localizable", "version", fallback: "Version")
  /// Overlay Label for Selecting Video Information/Settings
  internal static let video = L10n.tr("Localizable", "video", fallback: "Video")
  /// Section Title for the Video Player Settings Section
  internal static let videoPlayer = L10n.tr("Localizable", "videoPlayer", fallback: "Video Player")
  /// Section Title for the Video Player Type Setting between VLC, and AVKit
  internal static let videoPlayerType = L10n.tr("Localizable", "videoPlayerType", fallback: "Video Player Type")
  /// Represents the label for all Jellyfin Icons that are Yellow regardless of Backgound/Color Invert
  internal static let yellow = L10n.tr("Localizable", "yellow", fallback: "Yellow")
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
