//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import CollectionVGrid
import Combine
import Defaults
import Factory
import JellyfinAPI
import Nuke
import SwiftUI

struct ItemImageDetailsView: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - State, Observed, & Environment Objects

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @ObservedObject
    private var viewModel: ItemImagesViewModel

    // MARK: - Image Variable

    private let imageSource: ImageSource

    // MARK: - Navigation Title

    private let title: String

    // MARK: - Description Variables

    private let index: Int?
    private let width: Int?
    private let height: Int?
    private let language: String?
    private let provider: String?
    private let rating: Double?
    private let ratingType: RatingType?
    private let ratingVotes: Int?
    private let isLocal: Bool

    // MARK: - Image Actions

    private let onSave: (() -> Void)?
    private let onDelete: (() -> Void)?

    // MARK: - Dialog States

    @State
    private var error: Error?

    // MARK: - Collection Layout

    @State
    private var layout: CollectionVGridLayout = .minWidth(150)

    // MARK: - Initializer

    init(
        title: String,
        viewModel: ItemImagesViewModel,
        imageSource: ImageSource,
        index: Int? = nil,
        width: Int? = nil,
        height: Int? = nil,
        language: String? = nil,
        provider: String? = nil,
        rating: Double? = nil,
        ratingType: RatingType? = nil,
        ratingVotes: Int? = nil,
        isLocal: Bool,
        onSave: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.title = title
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.imageSource = imageSource
        self.index = index
        self.width = width
        self.height = height
        self.language = language
        self.provider = provider
        self.rating = rating
        self.ratingType = ratingType
        self.ratingVotes = ratingVotes
        self.isLocal = isLocal
        self.onSave = onSave
        self.onDelete = onDelete
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationBarTitle(title.localizedCapitalized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismissCoordinator()
            }
            .topBarTrailing {
                if viewModel.backgroundStates.contains(.refreshing) {
                    ProgressView()
                }
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case .deleted, .updated:
                    UIDevice.feedback(.success)
                    router.dismissCoordinator()
                case let .error(eventError):
                    UIDevice.feedback(.error)
                    error = eventError
                }
            }
            .errorMessage($error)
    }

    // MARK: - Content View

    @ViewBuilder
    var contentView: some View {
        List {
            HeaderSection(
                imageSource: imageSource,
                posterType: height ?? 0 > width ?? 0 ? .portrait : .landscape
            )

            DetailsSection(
                url: imageSource.url,
                index: index,
                language: language,
                width: width,
                height: height,
                provider: provider,
                rating: rating,
                ratingType: ratingType,
                ratingVotes: ratingVotes
            )

            if isLocal, let onDelete {
                DeleteButton {
                    onDelete()
                }
            }
        }
        .topBarTrailing {
            if !isLocal, let onSave {
                Button(L10n.save, action: onSave)
                    .buttonStyle(.toolbarPill)
            }
        }
    }
}
