//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import JellyfinAPI
import SwiftUI

/// Channel with associated programs
struct ChannelProgram: Hashable, Identifiable {

    let channel: BaseItemDto
    let programs: [BaseItemDto]

    init(channel: BaseItemDto, programs: [BaseItemDto]) {
        self.channel = channel

        self.programs = programs
            .sorted { first, second in
                guard let firstStart = first.startDate,
                      let secondStart = second.startDate
                else {
                    return false
                }
                return firstStart < secondStart
            }
    }

    var currentProgram: BaseItemDto? {
        programs.first { program in
            guard let start = program.startDate,
                  let end = program.endDate else { return false }

            return (start ... end).contains(Date.now)
        }
    }

    func program(after other: BaseItemDto) -> BaseItemDto? {
        guard let i = programs.firstIndex(of: other), i < programs.endIndex - 1 else {
            return nil
        }
        return programs[i.advanced(by: 1)]
    }

    var id: String? {
        channel.id
    }
}

// TODO: implement all protocols, pass from channel

extension ChannelProgram: Poster {

    func squareImageSources(
        maxWidth: CGFloat?,
        quality: Int?,
        environment: Empty
    ) -> [ImageSource] {
        channel.squareImageSources(
            maxWidth: maxWidth,
            quality: quality,
            environment: .default
        )
    }

    var preferredPosterDisplayType: PosterDisplayType {
        .square
    }

    var displayTitle: String {
        channel.displayTitle
    }

    var systemImage: String {
        channel.systemImage
    }

    func transform(image: Image, displayType: PosterDisplayType) -> some View {
        channel.transform(image: image, displayType: displayType)
    }
}

extension ChannelProgram: @MainActor LibraryElement {

    static func layout(for libraryStyle: LibraryStyle) -> CollectionVGridLayout {
        var padLayout: CollectionVGridLayout {
            switch libraryStyle.displayType {
            case .grid:
                .minWidth(150)
            case .list:
                .minWidth(250)
            }
        }

        var phoneLayout: CollectionVGridLayout {
            switch libraryStyle.displayType {
            case .grid:
                .columns(3)
            case .list:
                .columns(1)
            }
        }

        return UIDevice.isPhone ? phoneLayout : padLayout
    }

    @MainActor
    func libraryDidSelectElement(router: Router.Wrapper, in namespace: Namespace.ID) {
//        router.route(to: .videoPlayer(item: channel), in: namespace)
        router.route(to: .item(item: channel), in: namespace)
    }

    func makeGridBody(libraryStyle: LibraryStyle) -> some View {
        WithRouter { router in
            PosterButton(
                item: channel,
                type: .square
            ) { namespace in
                libraryDidSelectElement(router: router, in: namespace)
            }
        }
    }

    @ViewBuilder
    func makeListBody(libraryStyle: LibraryStyle) -> some View {
        WithNamespace { namespace in
            WithRouter { router in
                ListRow(insets: .init(vertical: 8, horizontal: EdgeInsets.edgePadding)) {
                    libraryDidSelectElement(router: router, in: namespace)
                } leading: {
                    VStack {
                        PosterImage(
                            item: channel,
                            type: .square
                        )

                        Text(channel.number ?? "")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .lineLimit(1, reservesSpace: true)
                            .foregroundStyle(Color.accentColor)
                    }
                    .frame(width: 60)
                } content: {
                    ChannelLibraryBody(channelProgram: self)
                }
                .backport
                .matchedTransitionSource(id: "item", in: namespace)
            }
        }
    }

    private struct ChannelLibraryBody: View {

        @CurrentDate
        private var currentDate: Date

        let channelProgram: ChannelProgram

        @ViewBuilder
        private var programListView: some View {
            VStack(alignment: .leading, spacing: 0) {
                if let currentProgram = channelProgram.currentProgram {
                    ProgressView(value: currentProgram.programProgress(relativeTo: currentDate) ?? 0)
                        .progressViewStyle(.playback)
                        .frame(height: 5)
                        .padding(.bottom, 5)
                        .foregroundStyle(.primary)

                    programLabel(for: currentProgram)
                        .fontWeight(.bold)

                    Group {
                        if let nextProgram = channelProgram.program(after: currentProgram) {
                            programLabel(for: nextProgram)

                            if let futureProgram = channelProgram.program(after: nextProgram) {
                                programLabel(for: futureProgram)
                            }
                        }
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .font(.footnote)
//            .id(channel.currentProgram)
        }

        @ViewBuilder
        private func programLabel(for program: BaseItemDto) -> some View {
            HStack {
                AlternateLayoutView(alignment: .leading) {
                    Text("00:00 AAA")
                } content: {
                    if let startDate = program.startDate {
                        Text(startDate, style: .time)
                    } else {
                        Text(String.emptyRuntime)
                    }
                }
                .monospacedDigit()

                Text(program.displayTitle)
            }
            .lineLimit(1)
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                Text(channelProgram.displayTitle)
                    .font(.body)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                if channelProgram.programs.isNotEmpty {
                    programListView
                }
            }
        }
    }
}
