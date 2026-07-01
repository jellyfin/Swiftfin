//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import FactoryKit
import JellyfinAPI
import SwiftUI

private let userViewLibraryListImageWidth: CGFloat = 110

struct UserViewLibrary: PagingLibrary {

    let hasNextPage: Bool = false
    let parent: TitledLibraryParent = .init(
        displayTitle: L10n.media,
        id: "user-views"
    )

    func libraryStyleOptions(environment: Empty) -> LibraryStyleOptions {
        UserViewLibraryElement.supportedLibraryStyleOptions
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [UserViewLibraryElement] {
        guard pageState.pageOffset == 0 else { return [] }

        let parameters = Paths.GetUserViewsParameters(userID: pageState.userSession.user.id)
        let request = Paths.getUserViews(parameters: parameters)

        async let userViews = pageState.userSession.client.send(request)
        async let currentUser = pageState.userSession.client.send(Paths.getCurrentUser)

        let excludedLibraryIDs = try await currentUser.value.configuration?.myMediaExcludes ?? []
        let elements = try await (userViews.value.items ?? [])
            .coalesced(property: \.collectionType, with: .folders)
            .intersecting(CollectionType.supportedCases, using: \.collectionType)
            .subtracting(excludedLibraryIDs, using: \.id)
            .map { item in
                if item.type == .userView, item.collectionType == .folders {
                    return item.mutating(\.type, with: .folder)
                }

                return item
            }
            .map(UserViewLibraryElement.userView)

        return elements
            .prepending(.favorites, if: Defaults[.Customization.Library.showFavorites])
    }
}

enum UserViewLibraryElement: Displayable, Hashable, Identifiable, LibraryElement, SystemImageable {

    case favorites
    case userView(BaseItemDto)

    static var supportedLibraryStyleOptions: LibraryStyleOptions {
        BaseItemKind.libraryStyleOptions(for: [.userView])
    }

    var displayTitle: String {
        switch self {
        case .favorites:
            L10n.favorites
        case let .userView(item):
            item.displayTitle
        }
    }

    var id: String {
        switch self {
        case .favorites:
            "favorites"
        case let .userView(item):
            item.id ?? item.displayTitle
        }
    }

    var systemImage: String {
        switch self {
        case .favorites:
            "heart.fill"
        case let .userView(item):
            if item.collectionType == .livetv {
                "tv.fill"
            } else {
                "folder.fill"
            }
        }
    }

    func libraryDidSelectElement(
        router: Router.Wrapper,
        in namespace: Namespace.ID
    ) {
        switch self {
        case .favorites:
            let library = ItemLibrary(
                parent: BaseItemDto(id: "favorites", name: L10n.favorites),
                filters: .favorites
            )
            router.route(to: .library(library: library), in: namespace)
        case let .userView(item):
            if item.collectionType == .livetv {
                router.route(
                    to: .library(library: LiveTVChannelLibrary()),
                    in: namespace
                )
            } else {
                router.route(
                    to: .library(library: ItemLibrary(parent: item, filters: .default)),
                    in: namespace
                )
            }
        }
    }

    @ViewBuilder
    func makeBody(
        libraryStyle: LibraryStyle,
        action: (() -> Void)?
    ) -> some View {
        switch libraryStyle.displayType {
        case .grid, .guide:
            UserViewLibraryGridElement(element: self)
        case .list:
            UserViewLibraryListElement(element: self)
        }
    }
}

private struct UserViewLibraryGridElement: View {

    @Default(.Customization.Library.randomImage)
    private var useRandomImage

    @Namespace
    private var namespace

    @Router
    private var router

    @State
    private var imageSources: [ImageSource] = []

    let element: UserViewLibraryElement

    private var isTitleLabelVisible: Bool {
        switch element {
        case .favorites:
            true
        case .userView:
            useRandomImage
        }
    }

    var body: some View {
        Button {
            element.libraryDidSelectElement(router: router, in: namespace)
        } label: {
            ImageView(imageSources)
                .image { image in
                    if isTitleLabelVisible {
                        titleLabelOverlay(with: image)
                    } else {
                        image
                    }
                }
                .placeholder { imageSource in
                    titleLabelOverlay(with: DefaultPlaceholderView(blurHash: imageSource.blurHash))
                }
                .failure {
                    Color.secondarySystemFill
                        .opacity(0.75)
                        .overlay {
                            titleLabel
                                .foregroundColor(.primary)
                        }
                }
                .id(imageSources.hashValue)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .posterStyle(.landscape)
                .backport
                .matchedTransitionSource(id: "item", in: namespace)
        }
        .onFirstAppear(perform: setImageSources)
        .backport
        .onChange(of: useRandomImage) { _, _ in
            setImageSources()
        }
        .buttonStyle(.card)
    }

    @ViewBuilder
    private var titleLabel: some View {
        Text(element.displayTitle)
            .font(.title2)
            .fontWeight(.semibold)
            .lineLimit(1)
            .multilineTextAlignment(.center)
            .frame(alignment: .center)
    }

    private func titleLabelOverlay(with content: some View) -> some View {
        ZStack {
            content

            Color.black
                .opacity(0.5)

            titleLabel
                .foregroundStyle(.white)
        }
    }

    private func setImageSources() {
        Task { @MainActor in
            imageSources = await element.libraryImageSources(useRandomImage: useRandomImage)
        }
    }
}

private struct UserViewLibraryListElement: View {

    @Default(.Customization.Library.randomImage)
    private var useRandomImage

    @Namespace
    private var namespace

    @Router
    private var router

    @State
    private var imageSources: [ImageSource] = []

    let element: UserViewLibraryElement

    var body: some View {
        ListRow(insets: .init(vertical: 8, horizontal: EdgeInsets.edgePadding)) {
            imageView
        } content: {
            Text(element.displayTitle)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        } action: {
            element.libraryDidSelectElement(router: router, in: namespace)
        }
        .backport
        .matchedTransitionSource(id: "item", in: namespace)
        .onFirstAppear(perform: setImageSources)
        .backport
        .onChange(of: useRandomImage) { _, _ in
            setImageSources()
        }
    }

    private var imageView: some View {
        ZStack {
            Color.secondarySystemFill
                .opacity(0.75)

            ImageView(imageSources)
                .placeholder { imageSource in
                    DefaultPlaceholderView(blurHash: imageSource.blurHash)
                }
                .failure {
                    Image(systemName: element.systemImage)
                        .foregroundStyle(.secondary)
                }
                .id(imageSources.hashValue)
        }
        .posterStyle(.landscape)
        .posterShadow()
        .frame(width: userViewLibraryListImageWidth)
    }

    private func setImageSources() {
        Task { @MainActor in
            imageSources = await element.libraryImageSources(useRandomImage: useRandomImage)
        }
    }
}

private extension UserViewLibraryElement {

    @MainActor
    func libraryImageSources(useRandomImage: Bool) async -> [ImageSource] {
        if useRandomImage {
            return await (try? randomItemImageSources()) ?? []
        }

        switch self {
        case .favorites:
            return []
        case let .userView(item):
            return [item.imageSource(.primary, maxWidth: 500)]
        }
    }

    @MainActor
    func randomItemImageSources() async throws -> [ImageSource] {
        guard let userSession = Container.shared.currentUserSession() else {
            throw UserSessionError.missingCurrentSession
        }

        if case let .userView(item) = self, item.collectionType == .livetv {
            return []
        }

        var parentID: String?
        var filters: [ItemTrait]?

        switch self {
        case .favorites:
            filters = [.isFavorite]
        case let .userView(item):
            parentID = item.id
        }

        var parameters = Paths.GetItemsParameters()
        parameters.filters = filters
        parameters.includeItemTypes = BaseItemKind.supportedCases
        parameters.isRecursive = true
        parameters.limit = 3
        parameters.parentID = parentID
        parameters.sortBy = [.random]
        parameters.userID = userSession.user.id

        let request = Paths.getItems(parameters: parameters)
        let response = try await userSession.client.send(request)

        return (response.value.items ?? [])
            .flatMap { $0.landscapeImageSources(maxWidth: 200) }
    }
}
