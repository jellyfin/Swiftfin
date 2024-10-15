//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

enum DeviceType: String, Displayable, Codable, CaseIterable {
    case android = "Device-android"
    case apple = "Device-apple"
    case chrome = "Device-browser-chrome"
    case edge = "Device-browser-edge"
    case edgechromium = "Device-browser-edgechromium"
    case finamp = "Device-finamp"
    case firefox = "Device-browser-firefox"
    case homeAssistant = "Device-homeassistant"
    case html5 = "Device-html5"
    case kodi = "Device-kodi"
    case msie = "Device-browser-msie"
    case opera = "Device-browser-opera"
    case playstation = "Device-playstation"
    case roku = "Device-roku"
    case safari = "Device-browser-safari"
    case samsungtv = "Device-samsungtv"
    case windows = "Device-windows"
    case xbox = "Device-xbox"
    case other = "Device-other"

    // MARK: - Initialize the Client

    init(client: String?, deviceName: String?) {
        switch client {
        case "Samsung Smart TV":
            self = .samsungtv
        case "Xbox One":
            self = .xbox
        case "Sony PS4":
            self = .playstation
        case "Kodi", "Kodi JellyCon":
            self = .kodi
        case "Jellyfin Android", "AndroidTV", "Android TV":
            self = .android
        case "Jellyfin Mobile (iOS)", "Jellyfin Mobile (iPadOS)", "Jellyfin iOS", "Jellyfin iPadOS", "Jellyfin tvOS", "Swiftfin iPadOS",
             "Swiftfin iOS", "Swiftfin tvOS", "Infuse", "Infuse-Direct", "Infuse-Library":
            self = .apple
        case "Home Assistant":
            self = .homeAssistant
        case "Jellyfin Roku":
            self = .roku
        case "Finamp":
            self = .finamp
        case "Jellyfin Web", "Jellyfin Web (Vue)":
            self = DeviceType(webBrowser: deviceName)
        default:
            self = .other
        }
    }

    // MARK: - Initialize the Browser if Jellyfin-Web

    private init(webBrowser: String?) {
        switch webBrowser {
        case "Opera", "Opera TV", "Opera Android":
            self = .opera
        case "Chrome", "Chrome Android":
            self = .chrome
        case "Firefox", "Firefox Android":
            self = .firefox
        case "Safari", "Safari iPad", "Safari iPhone":
            self = .safari
        case "Edge Chromium", "Edge Chromium Android", "Edge Chromium iPad", "Edge Chromium iPhone":
            self = .edgechromium
        case "Edge":
            self = .edge
        case "Internet Explorer":
            self = .msie
        default:
            self = .html5
        }
    }

    // MARK: - Client Image

    var image: ImageResource {
        ImageResource(
            name: self.rawValue,
            bundle: Bundle.main
        )
    }

    // MARK: - Client Color

    var clientColor: Color {
        switch self {
        case .samsungtv:
            return Color(red: 0.0, green: 0.44, blue: 0.74) // Samsung Blue
        case .xbox:
            return Color(red: 0.0, green: 0.5, blue: 0.0) // Xbox Green
        case .playstation:
            return Color(red: 0.0, green: 0.32, blue: 0.65) // PlayStation Blue
        case .kodi:
            return Color(red: 0.0, green: 0.58, blue: 0.83) // Kodi Blue
        case .android:
            return Color(red: 0.18, green: 0.8, blue: 0.44) // Android Green
        case .apple:
            return Color(red: 0.35, green: 0.35, blue: 0.35) // Apple Gray
        case .homeAssistant:
            return Color(red: 0.0, green: 0.55, blue: 0.87) // Home Assistant Blue
        case .roku:
            return Color(red: 0.31, green: 0.09, blue: 0.55) // Roku Purple
        case .finamp:
            return Color(red: 0.61, green: 0.32, blue: 0.88) // Finamp Purple
        case .chrome:
            return Color(red: 0.98, green: 0.75, blue: 0.18) // Chrome Yellow
        case .firefox:
            return Color(red: 1.0, green: 0.33, blue: 0.0) // Firefox Orange
        case .safari:
            return Color(red: 0.0, green: 0.48, blue: 1.0) // Safari Blue
        case .edgechromium:
            return Color(red: 0.0, green: 0.45, blue: 0.75) // Edge Chromium Blue
        case .edge:
            return Color(red: 0.19, green: 0.31, blue: 0.51) // Edge Gray
        case .msie:
            return Color(red: 0.0, green: 0.53, blue: 1.0) // Internet Explorer Blue
        case .opera:
            return Color(red: 1.0, green: 0.0, blue: 0.0) // Opera Red
        default:
            return Color.black
        }
    }

    // MARK: - Client Title

    var displayTitle: String {
        switch self {
        case .android:
            return "Android"
        case .apple:
            return "Apple"
        case .chrome:
            return "Chrome"
        case .edge:
            return "Edge"
        case .edgechromium:
            return "Edge Chromium"
        case .finamp:
            return "Finamp"
        case .firefox:
            return "Firefox"
        case .homeAssistant:
            return "Home Assistant"
        case .html5:
            return "HTML5"
        case .kodi:
            return "Kodi"
        case .msie:
            return "Internet Explorer"
        case .opera:
            return "Opera"
        case .playstation:
            return "PlayStation"
        case .roku:
            return "Roku"
        case .safari:
            return "Safari"
        case .samsungtv:
            return "Samsung TV"
        case .windows:
            return "Windows"
        case .xbox:
            return "Xbox"
        case .other:
            return "Other"
        }
    }
}
