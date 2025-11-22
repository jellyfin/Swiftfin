//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import Foundation
import JellyfinAPI
import Logging
import SwiftUI
import UIKit

extension SeriesEpisodeSelector {

    struct EpisodeHStack: View {

        private enum Constants {
            static let emptyCardID = "emptyCard"
            static let errorCardID = "errorCard"
            static let loadingCardID = "loadingCard"

            static var playButtonScrollDelay: TimeInterval {
                UIDevice.platformGeneration < 3 ? 0.35 : 0.1
            }
        }

        private enum FocusUpdateReason: String {
            case initial
            case focusGuide
            case pending
            case seasonChange
            case stateChange
        }

        private struct EpisodeFocusCoordinator {
            var pendingEpisodeID: String?
            var lastCommittedEpisodeID: String?
            var isApplyingFocus = false

            mutating func queuePendingEpisode(_ id: String?) {
                pendingEpisodeID = id
            }

            mutating func registerCommit(for id: String) {
                lastCommittedEpisodeID = id
                if pendingEpisodeID == id {
                    pendingEpisodeID = nil
                }
            }

            mutating func dropPending(ifMatching id: String) {
                if pendingEpisodeID == id {
                    pendingEpisodeID = nil
                }
            }

            mutating func reset() {
                pendingEpisodeID = nil
                lastCommittedEpisodeID = nil
                isApplyingFocus = false
            }

            mutating func invalidate(using visibleIDs: Set<String>) {
                if let last = lastCommittedEpisodeID, !visibleIDs.contains(last) {
                    lastCommittedEpisodeID = nil
                }

                if let pending = pendingEpisodeID, !visibleIDs.contains(pending) {
                    pendingEpisodeID = nil
                }
            }
        }

        private static let logger = Logger(label: "org.jellyfin.swiftfin.seriesEpisodeFocus")

        @EnvironmentObject
        private var focusGuide: FocusGuide

        @FocusState
        private var focusedEpisodeID: String?

        @ObservedObject
        var viewModel: SeasonItemViewModel

        @State
        private var didScrollToPlayButtonItem = false
        @State
        private var focusCoordinator = EpisodeFocusCoordinator()

        @StateObject
        private var proxy = CollectionHStackProxy()

        let playButtonItem: BaseItemDto?

        // MARK: - Content View

        private func contentView(viewModel: SeasonItemViewModel) -> some View {
            CollectionHStack(
                uniqueElements: viewModel.elements,
                id: \.unwrappedIDHashOrZero,
                columns: 3.5
            ) { episode in
                SeriesEpisodeSelector.EpisodeCard(episode: episode)
                    .focused($focusedEpisodeID, equals: episode.id)
                    .padding(.horizontal, 4)
            }
            .scrollBehavior(.continuousLeadingEdge)
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .proxy(proxy)
            .onFirstAppear {
                attemptScrollToPendingEpisodeIfNeeded()
            }
        }

        // MARK: - Body

        var body: some View {
            ZStack {
                PlaceholderHStack()

                Group {
                    switch viewModel.state {
                    case .content:
                        if viewModel.elements.isEmpty {
                            EmptyHStack(focusedEpisodeID: $focusedEpisodeID)
                        } else {
                            contentView(viewModel: viewModel)
                        }
                    case let .error(error):
                        ErrorHStack(viewModel: viewModel, error: error, focusedEpisodeID: $focusedEpisodeID)
                    case .initial, .refreshing:
                        LoadingHStack(focusedEpisodeID: $focusedEpisodeID)
                    }
                }.transition(.opacity.animation(.linear(duration: 0.1)))
            }
            .padding(.bottom, 45)
            .focusSection()
            .focusGuide(
                focusGuide,
                tag: "episodes",
                onContentFocus: {
                    applyFocusIfNeeded(reason: .focusGuide)
                },
                top: "belowHeader"
            )
            .onAppear {
                configurePendingFocusIfNeeded()
                applyFocusIfNeeded(reason: .initial)
            }
            .onChange(of: viewModel.id) { _, _ in
                didScrollToPlayButtonItem = false
                focusCoordinator.reset()
                configurePendingFocusIfNeeded(force: true)
                applyFocusIfNeeded(reason: .seasonChange)
            }
            .onChange(of: viewModel.state) { _, newValue in
                if newValue == .content {
                    configurePendingFocusIfNeeded()
                    attemptScrollToPendingEpisodeIfNeeded()
                }
                applyFocusIfNeeded(reason: .stateChange)
            }
            .onChange(of: focusedEpisodeID) { _, newValue in
                guard let newValue else { return }
                handleFocusedEpisodeChange(newValue)
            }
        }
    }

    private extension SeriesEpisodeSelector.EpisodeHStack {

        var episodeIDs: Set<String> {
            Set(viewModel.elements.compactMap(\.id))
        }

        var defaultEpisodeFocusID: String? {
            if playButtonIsInSeason {
                return playButtonItem?.id
            }

            return viewModel.elements.first?.id
        }

        var playButtonIsInSeason: Bool {
            guard let playButtonItem else { return false }
            return playButtonItem.seasonID == viewModel.id
        }

        func configurePendingFocusIfNeeded(force: Bool = false) {
            if force {
                let pendingID = playButtonIsInSeason ? playButtonItem?.id : nil
                focusCoordinator.queuePendingEpisode(pendingID)
                return
            }

            if focusCoordinator.pendingEpisodeID == nil,
               focusCoordinator.lastCommittedEpisodeID == nil
            {
                focusCoordinator.queuePendingEpisode(defaultEpisodeFocusID)
            }
        }

        func handleFocusedEpisodeChange(_ newValue: String) {
            if isPlaceholder(newValue) {
                focusCoordinator.dropPending(ifMatching: newValue)
                return
            }

            if episodeIDs.contains(newValue) {
                focusCoordinator.lastCommittedEpisodeID = newValue
            }
        }

        func attemptScrollToPendingEpisodeIfNeeded() {
            guard !didScrollToPlayButtonItem,
                  playButtonIsInSeason,
                  let pendingID = focusCoordinator.pendingEpisodeID,
                  let playButtonItem,
                  pendingID == playButtonItem.id
            else {
                return
            }

            didScrollToPlayButtonItem = true

            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.playButtonScrollDelay) {
                proxy.scrollTo(id: playButtonItem.unwrappedIDHashOrZero, animated: false)
                applyFocusIfNeeded(reason: .pending)
            }
        }

        func preferredFocusID() -> String? {
            switch viewModel.state {
            case .content:
                guard !viewModel.elements.isEmpty else {
                    focusCoordinator.lastCommittedEpisodeID = nil
                    return Constants.emptyCardID
                }

                if let pending = focusCoordinator.pendingEpisodeID,
                   episodeIDs.contains(pending)
                {
                    return pending
                }

                if let last = focusCoordinator.lastCommittedEpisodeID,
                   episodeIDs.contains(last)
                {
                    return last
                }

                return viewModel.elements.first?.id ?? Constants.emptyCardID
            case .error:
                return Constants.errorCardID
            case .initial, .refreshing:
                return Constants.loadingCardID
            }
        }

        func applyFocusIfNeeded(reason: FocusUpdateReason) {
            focusCoordinator.invalidate(using: episodeIDs)

            guard let targetID = preferredFocusID() else {
                return
            }

            guard !focusCoordinator.isApplyingFocus else {
                return
            }

            focusCoordinator.isApplyingFocus = true

            var transaction = Transaction(animation: .none)
            transaction.disablesAnimations = true

            withTransaction(transaction) {
                DispatchQueue.main.async {
                    focusedEpisodeID = targetID

                    if isPlaceholder(targetID) {
                        focusCoordinator.dropPending(ifMatching: targetID)
                    } else {
                        focusCoordinator.registerCommit(for: targetID)
                    }

                    focusCoordinator.isApplyingFocus = false
                    Self.logger.debug("Focused \(targetID) [reason: \(reason.rawValue)]")
                }
            }
        }

        func isPlaceholder(_ id: String) -> Bool {
            id == Constants.emptyCardID ||
                id == Constants.errorCardID ||
                id == Constants.loadingCardID
        }
    }

    // MARK: - Empty HStack

    struct EmptyHStack: View {

        let focusedEpisodeID: FocusState<String?>.Binding

        var body: some View {
            CollectionHStack(
                count: 1,
                columns: 3.5
            ) { _ in
                SeriesEpisodeSelector.EmptyCard()
                    .focused(focusedEpisodeID, equals: "emptyCard")
                    .padding(.horizontal, 4)
            }
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .scrollDisabled(true)
        }
    }

    // MARK: - Error HStack

    struct ErrorHStack: View {

        @ObservedObject
        var viewModel: SeasonItemViewModel

        let error: ErrorMessage
        let focusedEpisodeID: FocusState<String?>.Binding

        var body: some View {
            CollectionHStack(
                count: 1,
                columns: 3.5
            ) { _ in
                SeriesEpisodeSelector.ErrorCard(error: error)
                    .onSelect {
                        viewModel.send(.refresh)
                    }
                    .focused(focusedEpisodeID, equals: "errorCard")
                    .padding(.horizontal, 4)
            }
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .scrollDisabled(true)
        }
    }

    // MARK: - Loading HStack

    struct LoadingHStack: View {

        let focusedEpisodeID: FocusState<String?>.Binding

        var body: some View {
            CollectionHStack(
                count: 1,
                columns: 3.5
            ) { _ in
                SeriesEpisodeSelector.LoadingCard()
                    .focused(focusedEpisodeID, equals: "loadingCard")
                    .padding(.horizontal, 4)
            }
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .scrollDisabled(true)
        }
    }

    // MARK: - Placeholder HStack

    struct PlaceholderHStack: View {

        var body: some View {
            CollectionHStack(
                count: 1,
                columns: 3.5
            ) { _ in
                SeriesEpisodeSelector.EmptyCard()
                    .padding(.horizontal, 4)
            }
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .opacity(0)
            .allowsHitTesting(false)
            .scrollDisabled(true)
        }
    }
}
