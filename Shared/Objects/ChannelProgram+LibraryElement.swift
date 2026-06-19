//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

// TODO: think about what to do for many empty channel number entries

private let channelProgramListWidth: CGFloat = 80

extension ChannelProgram: LibraryElement {

    static var supportedLibraryStyleOptions: LibraryStyleOptions {
        BaseItemKind.libraryStyleOptions(for: [.tvChannel])
    }

    func libraryDidSelectElement(router: Router.Wrapper, in namespace: Namespace.ID) {
        guard let userSession = Container.shared.currentUserSession() else { return }

        router.route(
            to: .videoPlayer(
                provider: channel.getPlaybackItemProvider(userSession: userSession)
            ),
            in: namespace
        )
    }

    @ViewBuilder
    func makeBody(
        libraryStyle: LibraryStyle,
        action: (() -> Void)?
    ) -> some View {
        switch libraryStyle.displayType {
        case .grid:
            ChannelProgramLibraryGridElement(
                channelProgram: self,
                libraryStyle: libraryStyle,
                action: action
            )
        case .list:
            ChannelProgramLibraryListElement(
                channelProgram: self,
                libraryStyle: libraryStyle,
                action: action
            )
        }
    }
}

private struct ChannelProgramLibraryGridElement: View {

    @Namespace
    private var namespace

    @Router
    private var router

    let channelProgram: ChannelProgram
    let libraryStyle: LibraryStyle
    var action: (() -> Void)?

    private var resolvedLibraryStyle: LibraryStyle {
        channelProgram.resolvedLibraryStyle(libraryStyle)
    }

    var body: some View {
        Button {
            if let action {
                action()
            } else {
                channelProgram.libraryDidSelectElement(router: router, in: namespace)
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                PosterImage(item: channelProgram.channel, type: resolvedLibraryStyle.posterDisplayType)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .posterStyle(resolvedLibraryStyle.posterDisplayType)
                    .backport
                    .matchedTransitionSource(id: "item", in: namespace)
                    .posterShadow()

                VStack(alignment: .leading, spacing: 0) {
                    Text(channelProgram.displayTitle)
                        .font(.footnote)
                        .foregroundStyle(.primary)
                        .lineLimit(1, reservesSpace: true)

//                    AlternateLayoutView {
//                        // swiftlint:disable:next hard_coded_display_string
//                        Text(" ")
//                    } content: {
//                        if let channelNumber = channelProgram.channel.channelNumber {
//                            Text(channelNumber)
//                                .font(.subheadline)
//                                .lineLimit(1)
//                                .foregroundStyle(.secondary)
//                        }
//                    }
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary, .secondary)
    }
}

private struct ChannelProgramLibraryListElement: View {

    @Default(.accentColor)
    private var accentColor

    @Namespace
    private var namespace

    @Router
    private var router

    @State
    private var now: Date = .now

    let channelProgram: ChannelProgram
    let libraryStyle: LibraryStyle
    var action: (() -> Void)?

    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    private var resolvedLibraryStyle: LibraryStyle {
        channelProgram.resolvedLibraryStyle(libraryStyle)
    }

    var body: some View {
        ListRow(insets: .init(vertical: 8, horizontal: EdgeInsets.edgePadding)) {
            channelLogo
                .frame(width: channelProgramListWidth)
        } content: {
            VStack(alignment: .leading, spacing: 6) {
                Text(channelProgram.displayTitle)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if channelProgram.programs.isNotEmpty {
                    programListView
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } action: {
            if let action {
                action()
            } else {
                channelProgram.libraryDidSelectElement(router: router, in: namespace)
            }
        }
        .onReceive(timer) { newValue in
            now = newValue
        }
        .animation(.linear(duration: 0.2), value: channelProgram.currentProgram)
    }

    @ViewBuilder
    private var channelLogo: some View {
        VStack {
            PosterImage(item: channelProgram.channel, type: resolvedLibraryStyle.posterDisplayType)
                .posterStyle(resolvedLibraryStyle.posterDisplayType)
                .backport
                .matchedTransitionSource(id: "item", in: namespace)
                .posterShadow()

//            AlternateLayoutView {
//                // swiftlint:disable:next hard_coded_display_string
//                Text(" ")
//            } content: {
//                if let channelNumber = channelProgram.channel.channelNumber {
//                    Text(channelNumber)
//                        .font(.subheadline)
//                        .lineLimit(1)
//                        .foregroundStyle(.secondary)
//                }
//            }
        }
    }

    @ViewBuilder
    private var programListView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let currentProgram = channelProgram.currentProgram {
                ProgressBar(progress: currentProgram.programProgress(relativeTo: now) ?? 0)
                    .frame(height: 5)
                    .padding(.bottom, 5)
                    .foregroundStyle(accentColor)

                programLabel(for: currentProgram)
                    .font(.footnote)
                    .fontWeight(.bold)
            }

            if let nextProgram = channelProgram.programAfterCurrent(offset: 0) {
                programLabel(for: nextProgram)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let futureProgram = channelProgram.programAfterCurrent(offset: 1) {
                programLabel(for: futureProgram)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .id(channelProgram.currentProgram)
    }

    @ViewBuilder
    private func programLabel(for program: BaseItemDto) -> some View {
        HStack(alignment: .top) {
            AlternateLayoutView(alignment: .leading) {
                // swiftlint:disable:next hard_coded_display_string
                Text("00:00 AAA")
                    .monospacedDigit()
            } content: {
                if let startDate = program.startDate {
                    Text(startDate, style: .time)
                        .monospacedDigit()
                } else {
                    Text(String.emptyRuntime)
                }
            }

            Text(program.displayTitle)
        }
        .lineLimit(1)
    }
}
