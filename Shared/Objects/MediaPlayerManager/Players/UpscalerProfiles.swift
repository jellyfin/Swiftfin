//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults

enum Anime4KProfile: String, CaseIterable, Defaults.Serializable, Displayable {

    case modeAFast
    case modeBFast
    case modeCFast
    case modeAAFast
    case modeBBFast
    case modeCAFast

    var displayTitle: String {
        switch self {
        case .modeAFast: L10n.anime4KModeAFast
        case .modeBFast: L10n.anime4KModeBFast
        case .modeCFast: L10n.anime4KModeCFast
        case .modeAAFast: L10n.anime4KModeAAFast
        case .modeBBFast: L10n.anime4KModeBBFast
        case .modeCAFast: L10n.anime4KModeCAFast
        }
    }

    var description: String {
        switch self {
        case .modeAFast: L10n.anime4KModeAFastDescription
        case .modeBFast: L10n.anime4KModeBFastDescription
        case .modeCFast: L10n.anime4KModeCFastDescription
        case .modeAAFast: L10n.anime4KModeAAFastDescription
        case .modeBBFast: L10n.anime4KModeBBFastDescription
        case .modeCAFast: L10n.anime4KModeCAFastDescription
        }
    }

    var shaderNames: [String] {
        let restoreAndUpscale = ["Anime4K_Restore_CNN_M", "Anime4K_Upscale_CNN_x2_M"]
        let softRestoreAndUpscale = ["Anime4K_Restore_CNN_Soft_M", "Anime4K_Upscale_CNN_x2_M"]
        let denoiseAndUpscale = ["Anime4K_Upscale_Denoise_CNN_x2_M"]
        let restore = ["Anime4K_Restore_CNN_S"]
        let softRestore = ["Anime4K_Restore_CNN_Soft_S"]
        let preScale = [
            "Anime4K_AutoDownscalePre_x2",
            "Anime4K_AutoDownscalePre_x4",
        ]
        let passes: [String] = switch self {
        case .modeAFast: restoreAndUpscale + preScale
        case .modeBFast: softRestoreAndUpscale + preScale
        case .modeCFast: denoiseAndUpscale + preScale
        case .modeAAFast: restoreAndUpscale + restore + preScale
        case .modeBBFast: softRestoreAndUpscale + preScale + softRestore
        case .modeCAFast: denoiseAndUpscale + preScale + restore
        }

        return ["Anime4K_Clamp_Highlights"] + passes + ["Anime4K_Upscale_CNN_x2_S"]
    }
}

enum ArtCNNProfile: String, CaseIterable, Defaults.Serializable, Displayable {

    case standard
    case denoiseSharpen
    case denoiseSoften

    var displayTitle: String {
        switch self {
        case .standard: L10n.artCNNProfileStandard
        case .denoiseSharpen: L10n.artCNNProfileDenoiseSharpen
        case .denoiseSoften: L10n.artCNNProfileDenoiseSoften
        }
    }

    var description: String {
        switch self {
        case .standard: L10n.artCNNProfileStandardDescription
        case .denoiseSharpen: L10n.artCNNProfileDenoiseSharpenDescription
        case .denoiseSoften: L10n.artCNNProfileDenoiseSoftenDescription
        }
    }

    var shaderName: String {
        switch self {
        case .standard: "ArtCNN_C4F16"
        case .denoiseSharpen: "ArtCNN_C4F16_DS"
        case .denoiseSoften: "ArtCNN_C4F16_DN"
        }
    }
}
