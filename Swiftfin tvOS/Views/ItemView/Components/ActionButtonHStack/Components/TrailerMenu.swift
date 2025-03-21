//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct TrailerMenu: View {

        // MARK: - Generic Trailer Enum

        private enum Trailer: Displayable {
            case local(BaseItemDto)
            case remote(MediaURL)

            var displayTitle: String {
                switch self {
                case let .local(item):
                    return item.name ?? L10n.trailer
                case let .remote(url):
                    return url.name ?? L10n.trailer
                }
            }

            var section: String {
                switch self {
                case .local:
                    return TrailerType.local.displayTitle
                case .remote:
                    return TrailerType.remote.displayTitle
                }
            }
        }

        // MARK: - Stored Value

        @StoredValue(.User.enabledTrailers)
        private var enabledTrailers: TrailerType

        // MARK: - Focus State

        @FocusState
        private var isFocused: Bool

        // MARK: - Observed & Envirnoment Objects

        @ObservedObject
        var viewModel: ItemViewModel

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        // MARK: - Error State

        @State
        private var error: Error?

        // MARK: - Notification State

        @State
        private var selectedRemoteURL: MediaURL?

        // MARK: - Valid Trailers

        private var trailers: [Trailer] {
            var allTrailers = [Trailer]()

            /// If no trailers are enabled, return empty array
            if enabledTrailers == .none {
                return allTrailers
            }

            /// Add local trailers if enabled
            if enabledTrailers == .all || enabledTrailers == .local {
                for localTrailer in viewModel.localTrailers {
                    allTrailers.append(.local(localTrailer))
                }
            }

            /// Add remote trailers if enabled
            if enabledTrailers == .all || enabledTrailers == .remote {
                for remoteTrailer in viewModel.item.remoteTrailers ?? [] {
                    allTrailers.append(.remote(remoteTrailer))
                }
            }

            return allTrailers
        }

        // MARK: - Initializer

        init(viewModel: ItemViewModel) {
            self.viewModel = viewModel
        }

        // MARK: - Body

        var body: some View {
            ZStack {
                switch trailers.count {
                case 0:
                    EmptyView()
                case 1:
                    trailerButton
                default:
                    trailerMenu
                }
            }
            .alert(L10n.leavingSwiftfin, isPresented: .constant(selectedRemoteURL != nil)) {
                Button(L10n.cancel, role: .cancel) {
                    selectedRemoteURL = nil
                }
                Button(L10n.ok, role: .destructive) {
                    if let mediaURL = selectedRemoteURL {
                        playRemoteTrailer(mediaURL)
                        selectedRemoteURL = nil
                    }
                }
            } message: {
                L10n.leavingSwiftfinWarning.text
            }
        }

        // MARK: - Single Trailer Button

        private var trailerButton: some View {
            ActionButton(L10n.trailers, icon: "movieclapper", selectedIcon: "movieclapper.fill") {
                if let trailer = trailers.first {
                    playTrailer(trailer)
                }
            }
        }

        // MARK: - Multiple Trailers Menu Button

        private var trailerMenu: some View {
            ActionButton(L10n.trailers, icon: "movieclapper") {
                let groupedTrailers = Dictionary(grouping: trailers) { $0.section }

                ForEach(groupedTrailers.keys.sorted(), id: \.self) { section in
                    if let trailersInSection = groupedTrailers[section] {
                        Section(section) {
                            ForEach(Array(trailersInSection.enumerated()), id: \.offset) { _, trailer in
                                Button {
                                    playTrailer(trailer)
                                } label: {
                                    HStack {
                                        Text(trailer.displayTitle)
                                        Spacer()
                                        Image(systemName: trailerIcon(for: trailer))
                                    }
                                    .font(.body.weight(.bold))
                                }
                            }
                        }
                    }
                }
            }
            .errorMessage($error)
        }

        // MARK: - Play: Generic Trailer

        private func playTrailer(_ trailer: Trailer) {
            switch trailer {
            case let .local(item):
                playLocalTrailer(item)
            case let .remote(mediaURL):
                selectedRemoteURL = mediaURL
            }
        }

        // MARK: - Play: Local Trailer

        private func playLocalTrailer(_ trailer: BaseItemDto) {
            if let selectedMediaSource = trailer.mediaSources?.first {
                router.route(
                    to: \.videoPlayer,
                    OnlineVideoPlayerManager(item: trailer, mediaSource: selectedMediaSource)
                )
            } else {
                error = JellyfinAPIError("No media sources found")
            }
        }

        // MARK: - Play: Remote Trailer

        private func playRemoteTrailer(_ trailer: MediaURL) {
            if let url = trailer.url, let nsUrl = URL(string: url.description) {
                if UIApplication.shared.canOpenURL(nsUrl) {
                    UIApplication.shared.open(nsUrl, options: [:], completionHandler: { success in
                        if !success {
                            self.error = JellyfinAPIError(
                                """
                                Failed to open this trailer. Please ensure that you have the appropriate app to play this trailer installed on your device.

                                \(url)
                                """
                            )
                        }
                    })
                } else {
                    self.error = JellyfinAPIError(
                        """
                        Unable to open this trailer.

                        \(url)
                        """
                    )
                }
            } else {
                error = JellyfinAPIError("This trailer does not have a valid URL.")
            }
        }

        // MARK: - Trailer Icon

        private func trailerIcon(for trailer: Trailer) -> String {
            switch trailer {
            case .local:
                return "play"
            case .remote:
                return "arrow.up.forward"
            }
        }
    }
}
