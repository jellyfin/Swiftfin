//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import JellyfinAPI
import SwiftUI

extension SeriesEpisodeSelector {

    struct EpisodeHStack: View {

        enum _Element: Identifiable {
            case empty
            case episode(BaseItemDto)
            case error(Error)
            case loading

            var id: Int {
                switch self {
                case let .episode(episode):
                    episode.unwrappedIDHashOrZero
                default:
                    UUID().hashValue
                }
            }
        }

        @ObservedObject
        var viewModel: PagingSeasonViewModel

        @State
        private var didScrollToPlayButtonItem = false

        @StateObject
        private var proxy = CollectionHStackProxy()

        let playButtonItem: BaseItemDto?

        private var elements: [_Element] {
//            switch viewModel.state {
//            case .content:
//                if viewModel.elements.isEmpty {
//                    [.empty]
//                } else {
//                    viewModel.elements.map { .episode($0) }
//                }
//            case .error:
//                viewModel.error.map { error in
//                    [.error(error)]
//                } ?? []
//            case .initial, .refreshing:
            Array(repeating: _Element.loading, count: 10)
//            }
        }

        var body: some View {
            CollectionHStack(
                uniqueElements: elements,
                columns: UIDevice.isPhone ? 1.5 : 3.5
            ) { element in
                switch element {
                case .empty:
                    _ElementView(
                        title: L10n.noResults,
                        subtitle: .emptyDash,
                        description: L10n.noEpisodesAvailable,
                        action: {}
                    )
                case let .error(error):
                    _ElementView(
                        title: L10n.error,
                        subtitle: .emptyDash,
                        description: error.localizedDescription
                    ) {
                        viewModel.refresh()
                    }
                case .loading:
                    _ElementView(
                        title: String.random(count: 10 ..< 20),
                        subtitle: String.random(count: 7 ..< 12),
                        description: String.random(count: 20 ..< 80),
                        action: {}
                    )
                    .redacted(reason: .placeholder)
                case let .episode(episode):
                    SeriesEpisodeSelector.EpisodeCard(episode: episode)
                }
            }
            .clipsToBounds(false)
            .scrollBehavior(.continuousLeadingEdge)
            .insets(horizontal: EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .proxy(proxy)
            .scrollDisabled(viewModel.state != .content)
//            .onFirstAppear {
//                guard !didScrollToPlayButtonItem else { return }
//                didScrollToPlayButtonItem = true
//
//                // good enough?
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                    guard let playButtonItem else { return }
//                    proxy.scrollTo(id: playButtonItem.unwrappedIDHashOrZero, animated: false)
//                }
//            }
        }
    }
}

import Defaults

struct _ElementView<Content: View>: View {
    
    @Default(.accentColor)
    private var accentColor

    private let content: Content
    private let title: String
    private let subtitle: String
    private let description: String
    private let action: () -> Void

    init(
        title: String,
        subtitle: String,
        description: String,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.action = action
        self.content = content()
    }
    
    @ViewBuilder
    private var subtitleView: some View {
        Text(subtitle)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }

    @ViewBuilder
    private var titleView: some View {
        Text(title)
            .font(.body)
            .foregroundStyle(.primary)
            .lineLimit(1)
            .multilineTextAlignment(.leading)
            .padding(.bottom, 1)
    }

    @ViewBuilder
    private var descriptionView: some View {
        Text(description)
            .font(.caption)
            .fontWeight(.light)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .lineLimit(3, reservesSpace: true)
    }

    var body: some View {
        VStack(alignment: .leading) {
            content

            Button(action: action) {
                VStack(alignment: .leading) {
                    subtitleView

                    titleView

                    descriptionView

                    Text(L10n.seeMore)
                        .font(.caption)
                        .fontWeight(.light)
                        .foregroundStyle(accentColor)
                }
            }
            .foregroundStyle(.primary, .secondary)
        }
    }
}

extension _ElementView where Content == EmptyView {

    init(
        title: String,
        subtitle: String,
        description: String,
        action: @escaping () -> Void
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            description: description,
            action: action,
            content: { EmptyView() }
        )
    }
}
