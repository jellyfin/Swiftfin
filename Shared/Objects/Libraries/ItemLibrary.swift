//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import SwiftUI

@MainActor
struct ItemLibrary: PagingLibrary, SearchablePagingLibrary, WithRandomElementLibrary {

    struct Environment: WithDefaultValue {
        var grouping: BaseItemDto.Grouping?
        var filters: ItemFilterCollection

        static let `default`: Self = .init(
            grouping: nil,
            filters: .default
        )
    }

    let environment: Environment?
    let filterViewModel: FilterViewModel
    let parent: BaseItemDto

    init(
        parent: BaseItemDto,
        filters: ItemFilterCollection? = nil
    ) {
        var environment = Environment(
            grouping: parent.groupings?.defaultSelection,
            filters: filters ?? .default
        )

        if let id = parent.id, Defaults[.Customization.Library.rememberSort] {
            let storedFilters = StoredValues[.User.libraryFilters(parentID: id)]

            environment.filters.sortBy = storedFilters.sortBy
            environment.filters.sortOrder = storedFilters.sortOrder
        }

        self.environment = environment
        self.filterViewModel = .init(
            parent: parent,
            currentFilters: environment.filters
        )
        self.parent = parent
    }

    func makeMenuContent(environment: Binding<Environment>) -> AnyView {
        Group {
            if let groupings = parent.groupings, groupings.elements.isNotEmpty {
                Picker(
                    selection: environment.map(
                        getter: { $0.grouping },
                        setter: { .init(grouping: $0, filters: environment.wrappedValue.filters) }
                    )
                ) {
                    ForEach(groupings.elements) { grouping in
                        Text(grouping.displayTitle)
                            .tag(grouping as BaseItemDto.Grouping?)
                    }
                } label: {
                    Text(L10n.grouping)

                    if let grouping = environment.wrappedValue.grouping {
                        Text(grouping.displayTitle)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .eraseToAnyView()
    }

    func makeLibraryBody(
        viewModel: PagingLibraryViewModel<Self>,
        @ViewBuilder content: @escaping () -> some View
    ) -> AnyView {
        ItemLibraryBody(
            filterViewModel: filterViewModel,
            viewModel: viewModel,
            content: content
        )
        .eraseToAnyView()
    }

    func libraryStyleOptions(environment: Environment) -> LibraryStyleOptions {
        let itemTypes = environment.filters.itemTypes.isEmpty ?
            parent.supportedItemTypes(for: environment.grouping) :
            environment.filters.itemTypes

        return BaseItemKind.libraryStyleOptions(for: itemTypes)
    }

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = attachPage(
            to: attachFilters(
                to: makeBaseItemParameters(environment: environment),
                using: environment.filters
            ),
            pageState: pageState
        )
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getItems(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return normalize(response.value.items ?? [])
    }

    func retrieveRandomElement(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> BaseItemDto? {
        var parameters = attachFilters(
            to: makeBaseItemParameters(environment: environment),
            using: environment.filters
        )
        parameters.limit = 1
        parameters.sortBy = [.random]
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getItems(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.items?.first
    }

    func retrieveSearchPage(
        query: String,
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = attachPage(
            to: attachFilters(
                to: makeBaseItemParameters(environment: environment),
                using: environment.filters,
                isLetterFilterIncluded: false
            ),
            pageState: pageState
        )
        parameters.searchTerm = query
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getItems(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return normalize(response.value.items ?? [])
    }

    private func makeBaseItemParameters(environment: Environment) -> Paths.GetItemsParameters {
        var parameters = Paths.GetItemsParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = parent.supportedItemTypes(for: environment.grouping)
        parameters.isRecursive = parent.isRecursiveCollection(for: environment.grouping)
        parameters.sortBy = [.name]
        parameters.sortOrder = [.ascending]

        guard let parentID = parent.id else { return parameters }

        switch parent.libraryType {
        case .boxSet, .collectionFolder, .userView:
            parameters.parentID = parentID
        case .folder:
            parameters.parentID = parentID
            parameters.isRecursive = nil
        case .person:
            parameters.personIDs = [parentID]
        case .studio:
            parameters.studioIDs = [parentID]
        default:
            break
        }

        return parameters
    }

    private func normalize(_ items: [BaseItemDto]) -> [BaseItemDto] {
        items
            .filter { item in
                if let collectionType = item.collectionType {
                    return CollectionType.supportedCases.contains(collectionType)
                }

                return true
            }
            .map { item in
                if parent.libraryType == .folder, item.type == .collectionFolder {
                    return item.mutating(\.type, with: .folder)
                }

                return item
            }
    }

    private func attachFilters(
        to parameters: Paths.GetItemsParameters,
        using filters: ItemFilterCollection,
        isLetterFilterIncluded: Bool = true
    ) -> Paths.GetItemsParameters {
        var parameters = parameters
        parameters.filters = filters.traits
        parameters.genres = filters.genres.map(\.value)
        parameters.sortBy = filters.sortBy
        parameters.sortOrder = filters.sortOrder
        parameters.tags = filters.tags.map(\.value)
        parameters.years = filters.years.compactMap { Int($0.value) }

        if filters.itemTypes.isNotEmpty {
            parameters.includeItemTypes = filters.itemTypes
        }

        guard isLetterFilterIncluded else { return parameters }

        if filters.letter.first?.value == "#" {
            parameters.nameLessThan = "A"
        } else {
            parameters.nameStartsWith = filters.letter
                .map(\.value)
                .filter { $0 != "#" }
                .first
        }

        return parameters
    }

    private func attachPage(
        to parameters: Paths.GetItemsParameters,
        pageState: LibraryPageState
    ) -> Paths.GetItemsParameters {
        var parameters = parameters
        parameters.limit = pageState.pageSize
        parameters.startIndex = pageState.pageOffset
        return parameters
    }
}

private struct ItemLibraryBody<Content: View>: View {

    @Default(.Customization.Library.enabledDrawerFilters)
    private var enabledDrawerFilters
    #if os(tvOS)
    @Default(.Customization.Library.cinematicBackground)
    private var isCinematicBackgroundEnabled

    @FocusedValue(\.focusedPoster)
    private var focusedPoster

    #endif

    @ObservedObject
    private var viewModel: PagingLibraryViewModel<ItemLibrary>

    private let content: Content
    private let filterViewModel: FilterViewModel

    init(
        filterViewModel: FilterViewModel,
        viewModel: PagingLibraryViewModel<ItemLibrary>,
        @ViewBuilder content: () -> Content
    ) {
        self.filterViewModel = filterViewModel
        self.viewModel = viewModel
        self.content = content()
    }

    var body: some View {
        content
            .letterPickerBar(filterViewModel: filterViewModel)
            .onFirstAppear {
                Task {
                    await filterViewModel.getQueryFilters()
                }
            }
            .backport
            .onChange(of: filterViewModel.currentFilters) { _, newFilters in
                rememberSort(from: newFilters)
            }
            .onReceive(
                filterViewModel.$currentFilters
                    .dropFirst()
                    .removeDuplicates()
                    .debounce(for: 1, scheduler: RunLoop.main)
            ) { filters in
                viewModel.environment.filters = filters
            }
        #if os(tvOS)
            .background(alignment: .top) {
                if isCinematicBackgroundEnabled {
                    FadeContentTransitionView(
                        item: focusedPoster,
                        debounce: 0.5
                    ) { item in
                        ImageView(item?.landscapeImageSources(environment: .default) ?? [])
                            .failure {
                                EmptyView()
                            }
                            .aspectRatio(contentMode: .fill)
                    }
                    .blurred()
                    .ignoresSafeArea()
                }
            }
        #else
            .navigationBarFilterDrawer(
                viewModel: filterViewModel,
                types: enabledDrawerFilters
            )
        #endif
    }

    private func rememberSort(from filters: ItemFilterCollection) {
        guard let id = viewModel.library.parent.id,
              Defaults[.Customization.Library.rememberSort]
        else { return }

        let storedFilters = StoredValues[.User.libraryFilters(parentID: id)]
            .mutating(\.sortBy, with: filters.sortBy)
            .mutating(\.sortOrder, with: filters.sortOrder)

        StoredValues[.User.libraryFilters(parentID: id)] = storedFilters
    }
}
