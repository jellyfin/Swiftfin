//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation
import JellyfinAPI
import UIKit

// 001fC^ = dark grey plain blurhash

public extension BaseItemDto {
    
    // MARK: Images

    func getSeriesBackdropImageBlurHash() -> String {
        let rawImgURL = getSeriesBackdropImage(maxWidth: 1).absoluteString
        let imgTag = rawImgURL.components(separatedBy: "&tag=")[1]

        return imageBlurHashes?.backdrop?[imgTag] ?? "001fC^"
    }

    func getSeriesPrimaryImageBlurHash() -> String {
        let rawImgURL = getSeriesPrimaryImage(maxWidth: 1).absoluteString
        let imgTag = rawImgURL.components(separatedBy: "&tag=")[1]

        return imageBlurHashes?.primary?[imgTag] ?? "001fC^"
    }

    func getPrimaryImageBlurHash() -> String {
        let rawImgURL = getPrimaryImage(maxWidth: 1).absoluteString
        let imgTag = rawImgURL.components(separatedBy: "&tag=")[1]

        return imageBlurHashes?.primary?[imgTag] ?? "001fC^"
    }

    func getBackdropImageBlurHash() -> String {
        let rawImgURL = getBackdropImage(maxWidth: 1).absoluteString
        let imgTag = rawImgURL.components(separatedBy: "&tag=")[1]

        if rawImgURL.contains("Backdrop") {
            return imageBlurHashes?.backdrop?[imgTag] ?? "001fC^"
        } else {
            return imageBlurHashes?.primary?[imgTag] ?? "001fC^"
        }
    }

    func getBackdropImage(maxWidth: Int) -> URL {
        var imageType = ""
        var imageTag = ""
        var imageItemId = id ?? ""

        if primaryImageAspectRatio ?? 0.0 < 1.0 {
            imageType = "Backdrop"
            if !(backdropImageTags?.isEmpty ?? true) {
                imageTag = (backdropImageTags ?? [""])[0]
            }
        } else {
            imageType = "Primary"
            imageTag = imageTags?["Primary"] ?? ""
        }

        if imageTag == "" || imageItemId == "" {
            imageType = "Backdrop"
            if !(parentBackdropImageTags?.isEmpty ?? true) {
                imageTag = (parentBackdropImageTags ?? [""])[0]
                imageItemId = parentBackdropItemId ?? ""
            }
        }

        let x = UIScreen.main.nativeScale * CGFloat(maxWidth)
        let urlString =
        "\(SessionManager.main.currentLogin.server.uri)/Items/\(imageItemId)/Images/\(imageType)?maxWidth=\(String(Int(x)))&quality=96&tag=\(imageTag)"
        return URL(string: urlString)!
    }

    func getEpisodeLocator() -> String? {
        if let seasonNo = parentIndexNumber, let episodeNo = indexNumber {
            return L10n.seasonAndEpisode(String(seasonNo), String(episodeNo))
        }
        return nil
    }

    func getSeriesBackdropImage(maxWidth: Int) -> URL {
        let imageType = "Backdrop"
        let imageTag = (parentBackdropImageTags ?? [""])[0]

        let x = UIScreen.main.nativeScale * CGFloat(maxWidth)
        let urlString =
            "\(SessionManager.main.currentLogin.server.uri)/Items/\(parentBackdropItemId ?? "")/Images/\(imageType)?maxWidth=\(String(Int(x)))&quality=96&tag=\(imageTag)"
        return URL(string: urlString)!
    }

    func getSeriesPrimaryImage(maxWidth: Int) -> URL {
        let imageType = "Primary"
        let imageTag = seriesPrimaryImageTag ?? ""
        let x = UIScreen.main.nativeScale * CGFloat(maxWidth)
        let urlString =
            "\(SessionManager.main.currentLogin.server.uri)/Items/\(seriesId ?? "")/Images/\(imageType)?maxWidth=\(String(Int(x)))&quality=96&tag=\(imageTag)"
        return URL(string: urlString)!
    }

    func getPrimaryImage(maxWidth: Int) -> URL {
        let imageType = "Primary"
        var imageTag = imageTags?["Primary"] ?? ""
        var imageItemId = id ?? ""

        if imageTag == "" || imageItemId == "" {
            imageTag = seriesPrimaryImageTag ?? ""
            imageItemId = seriesId ?? ""
        }

        let x = UIScreen.main.nativeScale * CGFloat(maxWidth)

        let urlString =
            "\(SessionManager.main.currentLogin.server.uri)/Items/\(imageItemId)/Images/\(imageType)?maxWidth=\(String(Int(x)))&quality=96&tag=\(imageTag)"
        // print(urlString)
        return URL(string: urlString)!
    }

    // MARK: Calculations

    func getItemRuntime() -> String {
        let timeHMSFormatter: DateComponentsFormatter = {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .abbreviated
            formatter.allowedUnits = [.hour, .minute]
            return formatter
        }()

        guard let runTimeTicks = runTimeTicks,
              let text = timeHMSFormatter.string(from: Double(runTimeTicks / 10_000_000)) else { return "" }

        return text
    }

    func getItemProgressString() -> String {
        if userData?.playbackPositionTicks == nil || userData?.playbackPositionTicks == 0 {
            return ""
        }

        let remainingSecs = ((runTimeTicks ?? 0) - (userData?.playbackPositionTicks ?? 0)) / 10_000_000
        let proghours = Int(remainingSecs / 3600)
        let progminutes = Int((Int(remainingSecs) - (proghours * 3600)) / 60)
        if proghours != 0 {
            return "\(proghours)h \(String(progminutes).leftPad(toWidth: 2, withString: "0"))m"
        } else {
            return "\(String(progminutes))m"
        }
    }
    
    // MARK: ItemType
    
    enum ItemType: String {
        case movie = "Movie"
        case season = "Season"
        case episode = "Episode"
        case series = "Series"
        
        case unknown
        
        var showDetails: Bool {
            switch self {
            case .season, .series:
                return false
            default:
                return true
            }
        }
    }
    
    var itemType: ItemType {
        guard let originalType = self.type, let knownType = ItemType(rawValue: originalType)  else { return .unknown }
        return knownType
    }
    
    // MARK: PortraitHeaderViewURL
    
    func portraitHeaderViewURL(maxWidth: Int) -> URL {
        switch self.itemType {
        case .movie, .season, .series:
            return getPrimaryImage(maxWidth: maxWidth)
        case .episode:
            return getSeriesPrimaryImage(maxWidth: maxWidth)
        case .unknown:
            return getPrimaryImage(maxWidth: maxWidth)
        }
    }
}
