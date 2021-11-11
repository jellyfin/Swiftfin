/* SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import JellyfinAPI
import UIKit

extension BaseItemPerson {

    // MARK: Get Image
    func getImage(baseURL: String, maxWidth: Int) -> URL {
        let imageType = "Primary"
        let imageTag = primaryImageTag ?? ""

        let x = UIScreen.main.nativeScale * CGFloat(maxWidth)

        let urlString = "\(baseURL)/Items/\(id ?? "")/Images/\(imageType)?maxWidth=\(String(Int(x)))&quality=85&tag=\(imageTag)"
        return URL(string: urlString)!
    }

    func getBlurHash() -> String {
        let rawImgURL = getImage(baseURL: "", maxWidth: 1).absoluteString
        let imgTag = rawImgURL.components(separatedBy: "&tag=")[1]

        return imageBlurHashes?.primary?[imgTag] ?? "001fC^"
    }

    // MARK: First Role

    // Jellyfin will grab all roles the person played in the show which makes the role
    //    text too long. This will grab the first role which:
    //      - assumes that the most important role is the first
    //      - will also grab the last "(<text>)" instance, like "(voice)"
    func firstRole() -> String? {
        guard let role = self.role else { return nil }
        let split = role.split(separator: "/")
        guard split.count > 1 else { return role }

        guard let firstRole = split.first?.trimmingCharacters(in: CharacterSet(charactersIn: " ")), let lastRole = split.last?.trimmingCharacters(in: CharacterSet(charactersIn: " ")) else { return role }

        var final = firstRole

        if let lastOpenIndex = lastRole.lastIndex(of: "("), let lastClosingIndex = lastRole.lastIndex(of: ")") {
            let roleText = lastRole[lastOpenIndex...lastClosingIndex]
            final.append(" \(roleText)")
        }

        return final
    }
}

// MARK: PortraitImageStackable
extension BaseItemPerson: PortraitImageStackable {
    public func imageURLContsructor(maxWidth: Int) -> URL {
        return self.getImage(baseURL: SessionManager.main.currentLogin.server.currentURI, maxWidth: maxWidth)
    }

    public var title: String {
        return self.name ?? ""
    }

    public var description: String? {
        return self.firstRole()
    }

    public var blurHash: String {
        return self.getBlurHash()
    }

    public var failureInitials: String {
        guard let name = self.name else { return "" }
        let initials = name.split(separator: " ").compactMap({ String($0).first })
        return String(initials)
    }
}

// MARK: DiplayedType
extension BaseItemPerson {

    // Only displayed person types.
    // Will ignore people like "GuestStar"
    enum DisplayedType: String, CaseIterable {
        case actor = "Actor"
        case director = "Director"
        case writer = "Writer"
        case producer = "Producer"

        static var allCasesRaw: [String] {
            return self.allCases.map({ $0.rawValue })
        }
    }
}
