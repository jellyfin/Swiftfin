//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

private func anyPosterImageSources<P: Poster>(
    for poster: P,
    displayType: PosterDisplayType,
    environment: AnyPoster.Environment
) -> [ImageSource] {
    var posterEnvironment = P.Environment.default

    if var imageSourceEnvironment = posterEnvironment as? WithImageSourceOptions {
        imageSourceEnvironment.maxWidth = environment.maxWidth
        imageSourceEnvironment.maxHeight = environment.maxHeight
        imageSourceEnvironment.quality = environment.quality
        posterEnvironment = imageSourceEnvironment as! P.Environment
    }

    if var viewContextEnvironment = posterEnvironment as? WithViewContext {
        viewContextEnvironment.viewContext = environment.viewContext
        posterEnvironment = viewContextEnvironment as! P.Environment
    }

    return poster.imageSources(for: displayType, environment: posterEnvironment)
}

struct AnyPoster: Poster {

    struct ID: Hashable {
        let posterType: ObjectIdentifier
        let value: AnyHashable
    }

    struct Environment: WithDefaultValue, WithImageSourceOptions, WithViewContext {

        var maxWidth: CGFloat?
        var maxHeight: CGFloat?
        var quality: Int?
        var viewContext: ViewContext = .init()

        static var `default`: Self {
            .init()
        }
    }

    let _poster: any Poster

    private let _id: ID

    init<P: Poster>(_ poster: P) {
        self._poster = poster
        self._id = ID(
            posterType: ObjectIdentifier(P.self),
            value: AnyHashable(poster.id)
        )
    }

    var preferredPosterDisplayType: PosterDisplayType {
        _poster.preferredPosterDisplayType
    }

    var displayTitle: String {
        _poster.displayTitle
    }

    var subtitle: String? {
        _poster.subtitle
    }

    var systemImage: String {
        _poster.systemImage
    }

    var id: ID {
        _id
    }

    var posterLabel: some View {
        _poster.posterLabel
            .eraseToAnyView()
    }

    var posterContextMenu: some View {
        _poster.posterContextMenu
            .eraseToAnyView()
    }

    func posterOverlay(for displayType: PosterDisplayType) -> some View {
        _poster.posterOverlay(for: displayType)
            .eraseToAnyView()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func imageSources(
        for displayType: PosterDisplayType,
        environment: Environment
    ) -> [ImageSource] {
        anyPosterImageSources(
            for: _poster,
            displayType: displayType,
            environment: environment
        )
    }

    func transform(image: Image, displayType: PosterDisplayType) -> some View {
        _poster.transform(image: image, displayType: displayType)
            .eraseToAnyView()
    }

    static func == (lhs: AnyPoster, rhs: AnyPoster) -> Bool {
        lhs.id == rhs.id
    }
}
