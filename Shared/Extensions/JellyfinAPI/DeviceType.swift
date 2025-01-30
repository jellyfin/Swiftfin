//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

enum DeviceType: String, Displayable, Codable, CaseIterable {
    case android
    case apple
    case chrome
    case edge
    case edgechromium
    case finamp
    case firefox
    case homeAssistant
    case html5
    case kodi
    case msie
    case opera
    case playstation
    case roku
    case safari
    case samsungtv
    case webos
    case windows
    case xbox
    case other

    // MARK: - Display Title

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
        case .webos:
            return "WebOS"
        case .windows:
            return "Windows"
        case .xbox:
            return "Xbox"
        case .other:
            return L10n.other
        }
    }

    // MARK: - Initialize the Client

    init(client: String?, deviceName: String?) {
        guard let client = client?.lowercased() else {
            self = .other
            return
        }

        switch client {

        /* Android or Findroid */
        case let str where str.range(of: #"android|findroid"#, options: .regularExpression) != nil:
            self = .android

        /* Apple devices: iOS, tvOS, iPadOS, Swiftfin, or Infuse */
        case let str where str.range(of: #"ios|tvos|ipados|swiftfin|infuse"#, options: .regularExpression) != nil:
            self = .apple

        /* Finamp */
        case let str where str.range(of: #"finamp"#, options: .regularExpression) != nil:
            self = .finamp

        /* Home Assistant or HomeAssistant */
        case let str where str.range(of: #"home.assistant|homeassistant"#, options: .regularExpression) != nil:
            self = .homeAssistant

        /* Jellyfin Web or JellyfinWeb (Vue versions included) */
        case let str where str.range(of: #"jellyfin.web|jellyfinweb"#, options: .regularExpression) != nil:
            self = DeviceType(webBrowser: deviceName)

        /* Kodi or JellyCon */
        case let str where str.range(of: #"kodi|jellycon"#, options: .regularExpression) != nil:
            self = .kodi

        /* LG TV, LG Smart TV, or WebOS devices */
        case let str where str.range(of: #"lg.+tv|webos"#, options: .regularExpression) != nil:
            self = .webos

        /* PlayStation: Sony PS3, PS4, or any PlayStation */
        case let str where str.range(of: #"sony\sps[3-4]|playstation"#, options: .regularExpression) != nil:
            self = .playstation

        /* Roku devices */
        case let str where str.range(of: #"roku"#, options: .regularExpression) != nil:
            self = .roku

        /* Samsung TV, Samsung Smart TV, or devices running Tizen */
        case let str where str.range(of: #"samsung.+tv|tizen"#, options: .regularExpression) != nil:
            self = .samsungtv

        /* Xbox One or any Xbox device */
        case let str where str.range(of: #"xbox"#, options: .regularExpression) != nil:
            self = .xbox

        /* Default case for anything else */
        default:
            self = .other
        }
    }

    // MARK: - Initialize the Browser if Jellyfin-Web

    private init(webBrowser: String?) {
        guard let webBrowser = webBrowser?.lowercased() else {
            self = .html5
            return
        }

        switch webBrowser {

        /* Matches any string containing 'chrome' */
        case let str where str.range(of: #"chrome"#, options: .regularExpression) != nil:
            self = .chrome

        /* Matches any string containing 'edge chromium' or 'edgechromium' */
        case let str where str.range(of: #"edge.chromium|edgechromium"#, options: .regularExpression) != nil:
            self = .edgechromium

        /* Matches any string containing 'edge' but not 'chromium' */
        case let str
            where str.range(of: #"edge"#, options: .regularExpression) != nil && str
            .range(of: #"chromium"#, options: .regularExpression) == nil:
            self = .edge

        /* Matches any string containing 'firefox' */
        case let str where str.range(of: #"firefox"#, options: .regularExpression) != nil:
            self = .firefox

        /* Matches any string containing 'internet explorer', 'IE', 'MSIE', or 'MSFT IE' */
        case let str
            where str.range(of: #"internet.explorer|internetexplorer|ie\d|ie.\d|msie|msft.ie"#, options: .regularExpression) != nil:
            self = .msie

        /* Matches any string containing 'opera' */
        case let str where str.range(of: #"opera"#, options: .regularExpression) != nil:
            self = .opera

        /* Matches any string containing 'safari' */
        case let str where str.range(of: #"safari"#, options: .regularExpression) != nil:
            self = .safari

        /* Default case for anything else */
        default:
            self = .html5
        }
    }

    // MARK: - Client Image

    var image: ImageResource {
        switch self {
        case .android:
            return .deviceClientAndroid
        case .apple:
            return .deviceClientApple
        case .chrome:
            return .deviceBrowserChrome
        case .edge:
            return .deviceBrowserEdge
        case .edgechromium:
            return .deviceBrowserEdgechromium
        case .finamp:
            return .deviceClientFinamp
        case .firefox:
            return .deviceBrowserFirefox
        case .homeAssistant:
            return .deviceOtherHomeassistant
        case .html5:
            return .deviceBrowserHtml5
        case .kodi:
            return .deviceClientKodi
        case .msie:
            return .deviceBrowserMsie
        case .opera:
            return .deviceBrowserOpera
        case .playstation:
            return .deviceClientPlaystation
        case .roku:
            return .deviceClientRoku
        case .safari:
            return .deviceBrowserSafari
        case .samsungtv:
            return .deviceClientSamsungtv
        case .webos:
            return .deviceClientWebos
        case .windows:
            return .deviceClientWindows
        case .xbox:
            return .deviceClientXbox
        case .other:
            return .deviceOtherOther
        }
    }

    // MARK: - Client Color

    var clientColor: Color {
        switch self {
        case .android:
            return Color(red: 0.18, green: 0.8, blue: 0.44) // Android Green
        case .apple:
            return Color(red: 0.35, green: 0.35, blue: 0.35) // Apple Gray
        case .chrome:
            return Color(red: 0.98, green: 0.75, blue: 0.18) // Chrome Yellow
        case .edge:
            return Color(red: 0.19, green: 0.31, blue: 0.51) // Edge Gray
        case .edgechromium:
            return Color(red: 0.0, green: 0.45, blue: 0.75) // Edge Chromium Blue
        case .firefox:
            return Color(red: 1.0, green: 0.33, blue: 0.0) // Firefox Orange
        case .finamp:
            return Color(red: 0.61, green: 0.32, blue: 0.88) // Finamp Purple
        case .homeAssistant:
            return Color(red: 0.0, green: 0.55, blue: 0.87) // Home Assistant Blue
        case .kodi:
            return Color(red: 0.0, green: 0.58, blue: 0.83) // Kodi Blue
        case .msie:
            return Color(red: 0.0, green: 0.53, blue: 1.0) // Internet Explorer Blue
        case .opera:
            return Color(red: 1.0, green: 0.0, blue: 0.0) // Opera Red
        case .playstation:
            return Color(red: 0.0, green: 0.32, blue: 0.65) // PlayStation Blue
        case .roku:
            return Color(red: 0.31, green: 0.09, blue: 0.55) // Roku Purple
        case .safari:
            return Color(red: 0.0, green: 0.48, blue: 1.0) // Safari Blue
        case .samsungtv:
            return Color(red: 0.0, green: 0.44, blue: 0.74) // Samsung Blue
        case .webos:
            return Color(red: 0.6667, green: 0.1569, blue: 0.2745) // WebOS Pink
        case .xbox:
            return Color(red: 0.0, green: 0.5, blue: 0.0) // Xbox Green
        default:
            return Color.secondarySystemFill
        }
    }
}
