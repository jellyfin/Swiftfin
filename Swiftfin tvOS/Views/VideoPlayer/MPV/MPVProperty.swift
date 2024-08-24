//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

enum MPVProperty {
    static let videoParamsColormatrix = "video-params/colormatrix"
    static let videoParamsColorlevels = "video-params/colorlevels"
    static let videoParamsPrimaries = "video-params/primaries"
    static let videoParamsGamma = "video-params/gamma"
    static let videoParamsSigPeak = "video-params/sig-peak"
    static let videoParamsSceneMaxR = "video-params/scene-max-r"
    static let videoParamsSceneMaxG = "video-params/scene-max-g"
    static let videoParamsSceneMaxB = "video-params/scene-max-b"
    static let pause = "pause"
    static let pausedForCache = "paused-for-cache"
}
