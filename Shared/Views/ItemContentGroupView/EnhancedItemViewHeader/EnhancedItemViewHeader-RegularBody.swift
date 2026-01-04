//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension EnhancedItemViewHeader {

    struct RegularBody: View {

        @Environment(\.frameForParentView)
        private var frameForParentView

        @ObservedObject
        var viewModel: _ItemViewModel

        @Router
        private var router

        @ViewBuilder
        private var logo: some View {
            ImageView(viewModel.item.imageURL(.logo, maxHeight: 70))
                .placeholder { _ in
                    EmptyView()
                }
                .failure {
                    MaxHeightText(viewModel.item.displayTitle)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                }
                .aspectRatio(contentMode: .fit)
                .frame(height: 70, alignment: .bottom)
        }

        @ViewBuilder
        private var overlay: some View {
            HStack(alignment: .bottom, spacing: EdgeInsets.edgePadding) {
                VStack(alignment: .leading, spacing: 10) {
                    logo

                    VStack(alignment: .leading, spacing: 5) {
                        if let tagline = viewModel.item.taglines?.first {
                            Text(tagline)
                                .fontWeight(.bold)
                                .lineLimit(2)
                        }

                        if let overview = viewModel.item.overview {
                            SeeMoreText(overview) {
                                router.route(to: .itemOverview(item: viewModel.item))
                            }
                            .font(.footnote)
                            .lineLimit(3)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(alignment: .top) {
                        AttributesHStack(
                            item: viewModel.item,
                            mediaSource: viewModel.selectedMediaSource
                        )

                        DotHStack {
                            if let firstGenre = viewModel.item.genres?.first {
                                Text(firstGenre)
                            }

                            if let premiereYear = viewModel.item.premiereDateYear {
                                Text(premiereYear)
                            }

                            if let runtime = viewModel.item.runtime {
                                Text(runtime, format: .hourMinuteAbbreviated)
                            }
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .center, spacing: 10) {
                    if viewModel.item.presentPlayButton {
                        PlayButton(viewModel: viewModel)
                    }

                    ActionButtonHStack(
                        item: viewModel.item,
                        localTrailers: viewModel.localTrailers
                    )
                }
                #if os(tvOS)
                .frame(width: 450)
                #else
                .frame(maxWidth: 300)
                #endif
            }
            .edgePadding(.bottom)
            .background(
                alignment: .bottom,
                extendedBy: .init(horizontal: EdgeInsets.edgePadding)
            ) {
                Rectangle()
                    .fill(Material.ultraThin)
                    .maskLinearGradient {
                        (location: 0, opacity: 0)
                        (location: 0.5, opacity: 1)
                    }
            }
        }

        var body: some View {
            AlternateLayoutView(alignment: .bottom) {
                Color.clear
                    .aspectRatio(2, contentMode: .fit)
            } content: {
                overlay
                    .edgePadding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .colorScheme(.dark)
            }
            .backgroundParallaxHeader(
                multiplier: 0.3
            ) {
                AlternateLayoutView {
                    Color.clear
                        .aspectRatio(2, contentMode: .fit)
                } content: {
                    ImageView(
                        viewModel.item.landscapeImageSources(maxWidth: 1320, environment: .init(useParent: false))
                    )
                    .aspectRatio(contentMode: .fit)
                }
            }
            .scrollViewHeaderOffsetOpacity()
            .trackingFrame(
                in: .local,
                for: .scrollViewHeader,
                key: ScrollViewHeaderFrameKey.self
            )
            .environment(\.frameForParentView, frameForParentView.removingValue(for: .navigationStack))
            .preference(key: _ContentGroupCustomizationKey.self, value: .useOffsetNavigationBar)
            .preference(key: MenuContentKey.self) {
                //                if viewModel.userSession.user.permissions.items.canEditMetadata(item: viewModel.item) {
                #if os(iOS)
                MenuContentGroup(id: "test") {
                    Button(L10n.edit, systemImage: "pencil") {
                        router.route(to: .editItem(viewModel.item))
                        //                            router.route(to: .settings)
                    }
                }
                #endif
                //                }
            }
        }
    }
}

import Combine
import Factory
import JellyfinAPI

struct ItemWithValueAction<Value> {

    private let action: @MainActor (BaseItemDto, Value) -> Void

    init(
        action: @escaping @MainActor (BaseItemDto, Value) -> Void
    ) {
        self.action = action
    }

    @MainActor
    func callAsFunction(_ item: BaseItemDto, _ value: Value) {
        action(item, value)
    }
}

typealias ItemFavoriteAction = ItemWithValueAction<Bool>

extension EnvironmentValues {

    @Entry
    @MainActor
    var favoriteItemAction: ItemWithValueAction = .init { @MainActor item, isFavorited in
        let handler = Container.shared.itemUserDataHandler()
        handler.setFavoriteStatus(for: item, isFavorited: isFavorited)
    }
}

extension Container {

    var itemUserDataHandler: Factory<ItemUserDataHandler> {
        self { ItemUserDataHandler() }
            .singleton
    }
}

@MainActor
class ItemUserDataHandler: ViewModel {

    private var favoriteItemTasks: [String: Task<Void, Never>] = [:]

    private var favoriteItemsSubject: PassthroughSubject<(BaseItemDto, Bool), Never> = .init()

    override init() {
        super.init()

        favoriteItemsSubject
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .sink { @MainActor [weak self] item, isFavorited in
                self?._setFavoriteStatus(for: item, isFavorited: isFavorited)
            }
            .store(in: &cancellables)
    }

    func setFavoriteStatus(
        for item: BaseItemDto,
        isFavorited: Bool
    ) {
        favoriteItemsSubject.send((item, isFavorited))
    }

    private func _setFavoriteStatus(
        for item: BaseItemDto,
        isFavorited: Bool
    ) {
        guard let itemId = item.id else { return }

        favoriteItemTasks[itemId]?.cancel()

        let task = Task {
            do {

                try await Task.sleep(for: .seconds(3))

                let newUserData: UserItemDataDto

                if isFavorited {
                    newUserData = try await userSession.client.send(
                        Paths.markFavoriteItem(itemID: itemId)
                    ).value
                } else {
                    newUserData = try await userSession.client.send(
                        Paths.unmarkFavoriteItem(itemID: itemId)
                    ).value
                }

                Notifications[.itemUserDataDidChange].post(newUserData)
            } catch {
                print("Failed to update favorite status for item \(itemId): \(error)")
            }

            favoriteItemTasks[itemId] = nil
        }

        favoriteItemTasks[itemId] = task
    }
}
