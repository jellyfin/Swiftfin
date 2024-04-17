//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import UIKit

struct LiveTVChannelProgram: Hashable {
    let id = UUID()
    let channel: BaseItemDto
    let currentProgram: BaseItemDto?
    let programs: [BaseItemDto]
}

extension LiveTVChannelProgram: Poster {
    var displayTitle: String {
        guard let currentProgram else { return "None" }
        return currentProgram.displayTitle
    }

    var title: String {
        guard let currentProgram else { return "None" }
        switch currentProgram.type {
        case .episode:
            return currentProgram.seriesName ?? currentProgram.displayTitle
        default:
            return currentProgram.displayTitle
        }
    }

    var subtitle: String? {
        guard let currentProgram else { return "" }
        switch currentProgram.type {
        case .episode:
            return currentProgram.seasonEpisodeLabel
        case .video:
            return currentProgram.extraType?.displayTitle
        default:
            return nil
        }
    }

    var showTitle: Bool {
        guard let currentProgram else { return false }
        switch currentProgram.type {
        case .episode, .series, .movie, .boxSet, .collectionFolder:
            return Defaults[.Customization.showPosterLabels]
        default:
            return true
        }
    }

    var typeSystemImage: String? {
        guard let currentProgram else { return nil }
        switch currentProgram.type {
        case .episode, .movie, .series:
            return "film"
        case .folder:
            return "folder.fill"
        case .person:
            return "person.fill"
        case .boxSet:
            return "film.stack"
        default: return nil
        }
    }

    func portraitPosterImageSource(maxWidth: CGFloat) -> ImageSource {
        guard let currentProgram else { return ImageSource() }
        switch currentProgram.type {
        case .episode:
            return currentProgram.seriesImageSource(.primary, maxWidth: maxWidth)
        case .folder:
            return ImageSource()
        default:
            return currentProgram.imageSource(.primary, maxWidth: maxWidth)
        }
    }

    func landscapePosterImageSources(maxWidth: CGFloat, single: Bool = false) -> [ImageSource] {
        guard let currentProgram else { return [] }
        switch currentProgram.type {
        case .episode:
            if single || !Defaults[.Customization.Episodes.useSeriesLandscapeBackdrop] {
                return [currentProgram.imageSource(.primary, maxWidth: maxWidth)]
            } else {
                return [
                    currentProgram.seriesImageSource(.thumb, maxWidth: maxWidth),
                    currentProgram.seriesImageSource(.backdrop, maxWidth: maxWidth),
                    currentProgram.imageSource(.primary, maxWidth: maxWidth),
                ]
            }
        case .folder:
            return [currentProgram.imageSource(.primary, maxWidth: maxWidth)]
        case .video:
            return [currentProgram.imageSource(.primary, maxWidth: maxWidth)]
        default:
            return [
                currentProgram.imageSource(.thumb, maxWidth: maxWidth),
                currentProgram.imageSource(.backdrop, maxWidth: maxWidth),
            ]
        }
    }

    func cinematicPosterImageSources() -> [ImageSource] {
        guard let currentProgram else { return [] }
        switch currentProgram.type {
        case .episode:
            return [currentProgram.seriesImageSource(.backdrop, maxWidth: UIScreen.main.bounds.width)]
        default:
            return [currentProgram.imageSource(.backdrop, maxWidth: UIScreen.main.bounds.width)]
        }
    }
}
