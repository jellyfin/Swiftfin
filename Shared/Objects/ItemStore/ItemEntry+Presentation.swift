//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemEntry: @MainActor LibraryElement, @MainActor Poster {

    typealias Environment = BaseItemDto.Environment

    var displayTitle: String {
        snapshot.displayTitle
    }

    var systemImage: String {
        snapshot.systemImage
    }

    var subtitle: String? {
        snapshot.subtitle
    }

    var preferredPosterDisplayType: PosterDisplayType {
        snapshot.preferredPosterDisplayType
    }

    var supportedLibraryStyleOptions: LibraryStyleOptions {
        snapshot.supportedLibraryStyleOptions
    }

    func resolveEnvironment(_ environment: EnvironmentValues) -> Environment {
        snapshot.resolveEnvironment(environment)
    }

    func imageSources(for displayType: PosterDisplayType, environment: Environment) -> [ImageSource] {
        snapshot.imageSources(for: displayType, environment: environment)
    }

    func transform(image: Image, displayType: PosterDisplayType) -> some View {
        snapshot.transform(image: image, displayType: displayType)
    }

    var posterLabel: some View {
        snapshot.posterLabel
    }

    var posterContextMenu: some View {
        snapshot.posterContextMenu
    }

    func posterOverlay(for displayType: PosterDisplayType) -> some View {
        snapshot.posterOverlay(for: displayType)
    }

    func libraryDidSelectElement(router: Router.Wrapper, in namespace: Namespace.ID) {
        guard let value else { return }
        value.libraryDidSelectElement(router: router, in: namespace)
    }

    @ViewBuilder
    func makeBody(libraryStyle: LibraryStyle, action: (() -> Void)?) -> some View {
        if let value {
            value.makeBody(libraryStyle: libraryStyle, action: action)
        }
    }
}
