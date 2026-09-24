//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

typealias ImageSourceBuilder = ArrayBuilder<ImageSource>

/// A type that is displayed as a poster
protocol Poster: Displayable, Hashable, Identifiable, SystemImageable {

    associatedtype Environment: WithDefaultValue = Empty
    associatedtype ImageBody: View = Image
    associatedtype LabelBody: View = EmptyView
    associatedtype ContextMenuBody: View = EmptyView
    associatedtype OverlayBody: View = EmptyView

    var preferredPosterDisplayType: PosterDisplayType { get }

    /// Optional subtitle when used as a poster
    var subtitle: String? { get }

    func resolveEnvironment(_ environment: EnvironmentValues) -> Environment

    @ImageSourceBuilder
    func imageSources(
        for displayType: PosterDisplayType,
        environment: Environment
    ) -> [ImageSource]

    @MainActor
    @ViewBuilder
    func transform(image: Image, displayType: PosterDisplayType) -> ImageBody

    @MainActor
    @ViewBuilder
    var posterLabel: LabelBody { get }

    @MainActor
    @ViewBuilder
    var posterContextMenu: ContextMenuBody { get }

    @MainActor
    @ViewBuilder
    func posterOverlay(for displayType: PosterDisplayType) -> OverlayBody
}

extension Poster where ImageBody == Image {

    @MainActor
    func transform(image: Image) -> Image {
        image
    }

    @MainActor
    @ViewBuilder
    func transform(image: Image, displayType: PosterDisplayType) -> ImageBody {
        image
    }
}

extension Poster where LabelBody == EmptyView {

    @MainActor
    @ViewBuilder
    var posterLabel: LabelBody {
        EmptyView()
    }
}

extension Poster where ContextMenuBody == EmptyView {

    @MainActor
    @ViewBuilder
    var posterContextMenu: ContextMenuBody {
        EmptyView()
    }
}

extension Poster where OverlayBody == EmptyView {

    @MainActor
    @ViewBuilder
    func posterOverlay(for displayType: PosterDisplayType) -> OverlayBody {
        EmptyView()
    }
}

extension Poster {

    var subtitle: String? {
        nil
    }

    func resolveEnvironment(_: EnvironmentValues) -> Environment {
        .default
    }

    func imageSources(
        for displayType: PosterDisplayType,
        size: PosterDisplayType.Size,
        environment: Environment = .default
    ) -> [ImageSource] {
        var environment = environment

        if var imageSourceEnvironment = environment as? WithImageSourceOptions {
            imageSourceEnvironment.maxWidth = size.width(for: displayType)
            imageSourceEnvironment.quality = size.quality
            environment = imageSourceEnvironment as! Environment
        }

        return imageSources(for: displayType, environment: environment)
    }
}

extension View {

    @MainActor
    @ViewBuilder
    func posterContextMenu<Item: Poster>(
        for item: Item,
        @ViewBuilder preview: @escaping () -> some View
    ) -> some View {
        if Item.ContextMenuBody.self == EmptyView.self {
            self
        } else {
            contextMenu {
                item.posterContextMenu
            } preview: {
                preview()
            }
        }
    }
}
