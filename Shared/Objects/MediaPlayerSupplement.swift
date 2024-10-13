//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

// TODO: break out

struct AnyMediaPlayerSupplement: Equatable, Identifiable {

    let supplement: any MediaPlayerSupplement

    init(supplement: any MediaPlayerSupplement) {
        self.supplement = supplement
    }

    var id: String {
        supplement.id
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.supplement.id == rhs.supplement.id
    }
}

protocol MediaPlayerSupplement: Equatable, Identifiable<String> {

    associatedtype VideoPlayerBody: View

    var title: String { get }

    func makeBody() -> Self.VideoPlayerBody
}

extension MediaPlayerSupplement where VideoPlayerBody == EmptyView {

    func makeBody() -> EmptyView {
        EmptyView()
    }
}

extension MediaPlayerSupplement where ID == String {

    var id: String { title }
}

struct ChapterDrawerButton {

//    weak var manager: MediaPlayerManager?
    let title: String = "Chapters"
    
    private let chapters: [ChapterInfo.FullInfo]
    
    init() {
//        guard let chapters else { return [] }
//
//        let ranges: [Range<TimeInterval>] = chapters
//            .map(\.startTimeSeconds)
//            .appending(runTimeSeconds + 1)
//            .adjacentPairs()
//            .map { $0 ..< $1 }
//
//        return zip(chapters, ranges)
//            .enumerated()
//            .map { i, zip in
//
//                let parameters = Paths.GetItemImageParameters(
//                    maxWidth: 500,
//                    quality: 90,
//                    imageIndex: i
//                )
//
//                let request = Paths.getItemImage(
//                    itemID: id ?? "",
//                    imageType: ImageType.chapter.rawValue,
//                    parameters: parameters
//                )
//
//                let imageURL = Container.shared.currentUserSession()!
//                    .client
//                    .fullURL(with: request)
//
//                return .init(
//                    chapterInfo: zip.0,
//                    imageSource: .init(url: imageURL),
//                    secondsRange: zip.1
//                )
//            }
    }

    func makeBody() -> some View {
        Color.red
    }
}
