//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

@testable import Swiftfin
import SwiftUI
import XCTest

final class YouTubePosterLayoutTests: XCTestCase {

    /// Ensures landscape posters used by the YouTube tab render wider than tall (card aspect check).
    func testLandscapePosterRendersWiderThanTall() {
        let poster = DummyPoster()
        let view = PosterImage(item: poster, type: .landscape)
        let hosting = UIHostingController(rootView: view)

        // Force view loading and layout
        _ = hosting.view
        hosting.view.bounds = CGRect(x: 0, y: 0, width: 800, height: 600)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()

        let size = hosting.sizeThatFits(in: CGSize(width: 800, height: 600))

        XCTAssertGreaterThan(size.width, size.height, "Landscape poster should be wider than tall")
        XCTAssertGreaterThan(size.height, 0, "Height should be positive")
    }
}

private struct DummyPoster: Poster {
    let id: String = "dummy"
    var unwrappedIDHashOrZero: Int { id.hashValue }

    let displayTitle: String = "Dummy"
    var preferredPosterDisplayType: PosterDisplayType { .landscape }
    var systemImage: String { "film" }

    func portraitImageSources(maxWidth: CGFloat?, quality: Int?) -> [ImageSource] { [] }

    func landscapeImageSources(maxWidth: CGFloat?, quality: Int?) -> [ImageSource] {
        // Two sources to mirror the YouTube flow (thumb then primary)
        [ImageSource(url: nil), ImageSource(url: nil)]
    }

    func cinematicImageSources(maxWidth: CGFloat?, quality: Int?) -> [ImageSource] { [] }

    func squareImageSources(maxWidth: CGFloat?, quality: Int?) -> [ImageSource] { [] }

    func thumbImageSources() -> [ImageSource] { [] }

    @MainActor
    func transform(image: Image) -> some View { image }
}
