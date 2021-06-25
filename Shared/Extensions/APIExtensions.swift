/* SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import JellyfinAPI
import UIKit

// 001fC^ = dark grey plain blurhash

extension BaseItemDto {

    // MARK: Images
    func getSeriesBackdropImageBlurHash() -> String {
        let rawImgURL = self.getSeriesBackdropImage(maxWidth: 1).absoluteString
        let imgTag = rawImgURL.components(separatedBy: "&tag=")[1]

        return self.imageBlurHashes?.backdrop?[imgTag] ?? "001fC^"
    }

    func getSeriesPrimaryImageBlurHash() -> String {
        let rawImgURL = self.getSeriesPrimaryImage(maxWidth: 1).absoluteString
        let imgTag = rawImgURL.components(separatedBy: "&tag=")[1]

        return self.imageBlurHashes?.primary?[imgTag] ?? "001fC^"
    }

    func getPrimaryImageBlurHash() -> String {
        let rawImgURL = self.getPrimaryImage(maxWidth: 1).absoluteString
        let imgTag = rawImgURL.components(separatedBy: "&tag=")[1]

        return self.imageBlurHashes?.primary?[imgTag] ?? "001fC^"
    }

    func getBackdropImageBlurHash() -> String {
        let rawImgURL = self.getBackdropImage(maxWidth: 1).absoluteString
        let imgTag = rawImgURL.components(separatedBy: "&tag=")[1]

        if rawImgURL.contains("Backdrop") {
            return self.imageBlurHashes?.backdrop?[imgTag] ?? "001fC^"
        } else {
            return self.imageBlurHashes?.primary?[imgTag] ?? "001fC^"
        }
    }

    func getBackdropImage(maxWidth: Int) -> URL {
        var imageType = ""
        var imageTag = ""
        var imageItemId = self.id ?? ""

        if self.primaryImageAspectRatio ?? 0.0 < 1.0 {
            imageType = "Backdrop"
            if !(self.backdropImageTags?.isEmpty ?? true) {
                imageTag = (self.backdropImageTags ?? [""])[0]
            }
        } else {
            imageType = "Primary"
            imageTag = self.imageTags?["Primary"] ?? ""
        }

        if imageTag == "" || imageItemId == "" {
            imageType = "Backdrop"
            if !(self.parentBackdropImageTags?.isEmpty ?? true) {
                imageTag = (self.parentBackdropImageTags ?? [""])[0]
                imageItemId = self.parentBackdropItemId ?? ""
            }
        }

        let x = UIScreen.main.nativeScale * CGFloat(maxWidth)
        let urlString = "\(ServerEnvironment.current.server.baseURI!)/Items/\(imageItemId)/Images/\(imageType)?maxWidth=\(String(Int(x)))&quality=60&tag=\(imageTag)"
        return URL(string: urlString)!
    }

    func getSeriesBackdropImage(maxWidth: Int) -> URL {
        let imageType = "Backdrop"
        let imageTag = (self.parentBackdropImageTags ?? [""])[0]

        let x = UIScreen.main.nativeScale * CGFloat(maxWidth)
        let urlString = "\(ServerEnvironment.current.server.baseURI!)/Items/\(self.parentBackdropItemId ?? "")/Images/\(imageType)?maxWidth=\(String(Int(x)))&quality=60&tag=\(imageTag)"
        return URL(string: urlString)!
    }

    func getSeriesPrimaryImage(maxWidth: Int) -> URL {
        let imageType = "Primary"
        let imageTag = self.seriesPrimaryImageTag ?? ""
        let x = UIScreen.main.nativeScale * CGFloat(maxWidth)
        let urlString = "\(ServerEnvironment.current.server.baseURI!)/Items/\(self.seriesId ?? "")/Images/\(imageType)?maxWidth=\(String(Int(x)))&quality=60&tag=\(imageTag)"
        return URL(string: urlString)!
    }

    func getPrimaryImage(maxWidth: Int) -> URL {
        let imageType = "Primary"
        var imageTag = self.imageTags?["Primary"] ?? ""
        var imageItemId = self.id ?? ""

        if imageTag == "" || imageItemId == "" {
            imageTag = self.seriesPrimaryImageTag ?? ""
            imageItemId = self.seriesId ?? ""
        }

        let x = UIScreen.main.nativeScale * CGFloat(maxWidth)

        let urlString = "\(ServerEnvironment.current.server.baseURI!)/Items/\(imageItemId)/Images/\(imageType)?maxWidth=\(String(Int(x)))&quality=60&tag=\(imageTag)"
        return URL(string: urlString)!
    }

    // MARK: Calculations
    func getItemRuntime() -> String {
        let timeHMSFormatter: DateComponentsFormatter = {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .brief
            formatter.allowedUnits = [.hour, .minute]
            return formatter
        }()

        let text = timeHMSFormatter.string(from: Double(self.runTimeTicks! / 10_000_000)) ?? ""

        return text
    }

    func getItemProgressString() -> String {
        if self.userData?.playbackPositionTicks == nil || self.userData?.playbackPositionTicks == 0 {
            return ""
        }

        let remainingSecs = ((self.runTimeTicks ?? 0) - (self.userData?.playbackPositionTicks ?? 0)) / 10_000_000
        let proghours = Int(remainingSecs / 3600)
        let progminutes = Int((Int(remainingSecs) - (proghours * 3600)) / 60)
        if proghours != 0 {
            return "\(proghours)h \(String(progminutes).leftPad(toWidth: 2, withString: "0"))m"
        } else {
            return "\(String(progminutes))m"
        }
    }
}

func round(_ value: Double, toNearest: Double) -> Double {
  return round(value / toNearest) * toNearest
}

extension BaseItemPerson {
    func getImage(baseURL: String, maxWidth: Int) -> URL {
        let imageType = "Primary"
        let imageTag = self.primaryImageTag ?? ""

        let x = UIScreen.main.nativeScale * CGFloat(maxWidth)

        let urlString = "\(baseURL)/Items/\(self.id ?? "")/Images/\(imageType)?maxWidth=\(String(Int(x)))&quality=60&tag=\(imageTag)"
        return URL(string: urlString)!
    }

    func getBlurHash() -> String {
        let rawImgURL = self.getImage(baseURL: "", maxWidth: 1).absoluteString
        let imgTag = rawImgURL.components(separatedBy: "&tag=")[1]

        return self.imageBlurHashes?.primary?[imgTag] ?? "001fC^"
    }
}
