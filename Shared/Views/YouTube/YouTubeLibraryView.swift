//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI
import UIKit

enum YouTubeChannelRailLayout {
    static let expandedWidth: CGFloat = 325
    static let collapsedWidth: CGFloat = 105
    static let horizontalPadding: CGFloat = 12
    static let verticalPadding: CGFloat = 12
}

struct YouTubeLibraryView: View {

    @StateObject
    private var viewModel: YouTubeLibraryViewModel

    @Router
    private var router

    #if os(tvOS)
    @FocusState
    private var focusedChannelID: String?
    #endif

    @State
    private var isChannelRailExpanded = false

    init(viewModel: YouTubeLibraryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)

        if let id = viewModel.parent?.id {
            StoredValues[.User.libraryPosterType(parentID: id)] = .landscape
            StoredValues[.User.libraryDisplayType(parentID: id)] = .grid
        }
    }

    private func avatar(for channel: BaseItemDto) -> some View {
        let imageSource = channel.imageSource(.primary, maxWidth: 90)

        return Group {
            if let url = imageSource.url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Circle()
                            .fill(Color.secondarySystemFill)
                            .overlay {
                                Text(channel.displayTitle.initials)
                                    .font(.footnote.bold())
                            }
                    }
                }
            } else {
                Circle()
                    .fill(Color.secondarySystemFill)
                    .overlay {
                        Text(channel.displayTitle.initials)
                            .font(.footnote.bold())
                    }
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
    }

    private func play(_ item: BaseItemDto) {
        let provider = MediaPlayerItemProvider(item: item) { item in
            try await MediaPlayerItem.build(for: item)
        }

        router.route(to: .videoPlayer(provider: provider))
    }

    private func channelRow(title: String, isSelected: Bool, isExpanded: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(Color.secondarySystemFill)
                    .overlay {
                        Text(title.initials)
                            .font(.footnote.bold())
                    }
                    .frame(width: 44, height: 44)

                if isExpanded {
                    Text(title)
                        .lineLimit(1)

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: isExpanded ? .leading : .center)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
    }

    private func channelRow(channel: BaseItemDto) -> some View {
        let isSelected = viewModel.selectedChannelID == channel.id
        let channelFocusID = channel.id ?? channel.displayTitle

        return Button {
            viewModel.selectedChannelID = channel.id
        } label: {
            HStack {
                avatar(for: channel)

                if isChannelRailExpanded {
                    Text(channel.displayTitle)
                        .lineLimit(1)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: isChannelRailExpanded ? .leading : .center)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        #if os(tvOS)
        .focused($focusedChannelID, equals: channelFocusID)
        #endif
    }

    private var channelList: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isChannelRailExpanded {
                Text(L10n.channels)
                    .font(.headline)
            }

            channelRow(
                title: L10n.allChannels,
                isSelected: viewModel.selectedChannelID == nil,
                isExpanded: isChannelRailExpanded
            ) {
                viewModel.selectedChannelID = nil
            }
            #if os(tvOS)
            .focused($focusedChannelID, equals: "all")
            #endif

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    if viewModel.channels.isEmpty {
                        Text(L10n.noChannelsFound)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.channels, id: \.id) { channel in
                            channelRow(channel: channel)
                        }
                    }
                }
            }
        }
        .padding(.vertical, YouTubeChannelRailLayout.verticalPadding)
        .padding(.horizontal, YouTubeChannelRailLayout.horizontalPadding)
        .frame(width: isChannelRailExpanded ? YouTubeChannelRailLayout.expandedWidth : YouTubeChannelRailLayout.collapsedWidth)
        .background({
            #if os(tvOS)
            Color.secondary.opacity(0.08)
            #else
            Color(UIColor.secondarySystemBackground)
            #endif
        }())
        .animation(.easeInOut(duration: 0.2), value: isChannelRailExpanded)
    }

    var body: some View {
        HStack(spacing: 0) {
            channelList

            Divider()

            PagingLibraryView(
                viewModel: viewModel,
                onSelect: play,
                posterTypeOverride: .landscape,
                displayTypeOverride: .grid
            )
            .padding(.leading, 8)
            .overlay {
                if viewModel.state == .content, viewModel.elements.isEmpty {
                    VStack(spacing: 8) {
                        Text(L10n.noVideosYet)
                            .font(.headline)
                        Text(L10n.noYouTubeLibrariesDetectedDescription)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(L10n.youtube)
        .task {
            await MainActor.run {
                viewModel.send(.refresh)
            }
        }
        #if os(tvOS)
        .onAppear {
            focusedChannelID = viewModel.selectedChannelID ?? "all"
            isChannelRailExpanded = focusedChannelID != nil
        }
        .onChange(of: viewModel.selectedChannelID) { _, newValue in
            focusedChannelID = newValue ?? "all"
            withAnimation(.easeInOut(duration: 0.2)) {
                isChannelRailExpanded = focusedChannelID != nil
            }
        }
        .onChange(of: focusedChannelID) { _, newValue in
            withAnimation(.easeInOut(duration: 0.2)) {
                isChannelRailExpanded = newValue != nil
            }
        }
        #endif
    }
}
