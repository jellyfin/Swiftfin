//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import UIKit

extension ImageResource {

    // MARK: - Browsers

    static let browserChrome = ImageResource(name: "Device-browser-chrome", bundle: .main)
    static let browserEdge = ImageResource(name: "Device-browser-edge", bundle: .main)
    static let browserEdgeChromium = ImageResource(name: "Device-browser-edgechromium", bundle: .main)
    static let browserFirefox = ImageResource(name: "Device-browser-firefox", bundle: .main)
    static let browserHtml5 = ImageResource(name: "Device-browser-html5", bundle: .main)
    static let browserMsie = ImageResource(name: "Device-browser-msie", bundle: .main)
    static let browserOpera = ImageResource(name: "Device-browser-opera", bundle: .main)
    static let browserSafari = ImageResource(name: "Device-browser-safari", bundle: .main)

    // MARK: - Clients

    static let clientAndroid = ImageResource(name: "Device-client-android", bundle: .main)
    static let clientApple = ImageResource(name: "Device-client-apple", bundle: .main)
    static let clientFinamp = ImageResource(name: "Device-client-finamp", bundle: .main)
    static let clientKodi = ImageResource(name: "Device-client-kodi", bundle: .main)
    static let clientPlaystation = ImageResource(name: "Device-client-playstation", bundle: .main)
    static let clientRoku = ImageResource(name: "Device-client-roku", bundle: .main)
    static let clientSamsung = ImageResource(name: "Device-client-samsung", bundle: .main)
    static let clientWebOS = ImageResource(name: "Device-client-webos", bundle: .main)
    static let clientWindows = ImageResource(name: "Device-client-windows", bundle: .main)
    static let clientXbox = ImageResource(name: "Device-client-xbox", bundle: .main)

    // MARK: - Other Devices

    static let deviceHomeAssistant = ImageResource(name: "Device-other-homeassistant", bundle: .main)
    static let deviceOther = ImageResource(name: "Device-other-other", bundle: .main)
}
