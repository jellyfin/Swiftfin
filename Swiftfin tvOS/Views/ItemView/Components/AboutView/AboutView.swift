//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct AboutView: View {

        @EnvironmentObject
        private var itemRouter: ItemCoordinator.Router
        @ObservedObject
        var viewModel: ItemViewModel

        @State
        private var presentOverviewAlert = false
        @State
        private var presentSubtitlesAlert = false
        @State
        private var presentAudioAlert = false

        var body: some View {
            VStack(alignment: .leading) {

                L10n.about.text
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.leading, 50)

                ScrollView(.horizontal) {
                    HStack {
                        ImageView(
                            viewModel.item.type == .episode ? viewModel.item.seriesImageSource(.primary, maxWidth: 300) : viewModel.item
                                .imageSource(.primary, maxWidth: 300)
                        )
                        .failure {
                            InitialFailureView(viewModel.item.title.initials)
                        }
                        .posterStyle(type: .portrait, width: 270)

                        AboutViewCard(
                            isShowingAlert: $presentOverviewAlert,
                            title: viewModel.item.displayName,
                            text: viewModel.item.overview ?? L10n.noOverviewAvailable
                        )

                        if let subtitleStreams = viewModel.playButtonItem?.subtitleStreams, !subtitleStreams.isEmpty {
                            AboutViewCard(
                                isShowingAlert: $presentSubtitlesAlert,
                                title: L10n.subtitles,
                                text: subtitleStreams.compactMap(\.displayTitle).joined(separator: ", ")
                            )
                        }

                        if let audioStreams = viewModel.playButtonItem?.audioStreams, !audioStreams.isEmpty {
                            AboutViewCard(
                                isShowingAlert: $presentAudioAlert,
                                title: L10n.audio,
                                text: audioStreams.compactMap(\.displayTitle).joined(separator: ", ")
                            )
                        }
                    }
                    .padding(.horizontal, 50)
                    .padding(.top)
                    .padding(.bottom, 100)
                }
            }
            .alert(viewModel.item.displayName, isPresented: $presentOverviewAlert) {
                Button {
                    presentOverviewAlert = false
                } label: {
                    L10n.close.text
                }
            } message: {
                if let overview = viewModel.item.overview {
                    overview.text
                } else {
                    L10n.noOverviewAvailable.text
                }
            }
            .alert(L10n.subtitles, isPresented: $presentSubtitlesAlert) {
                Button {
                    presentSubtitlesAlert = false
                } label: {
                    L10n.close.text
                }
            } message: {
                viewModel.item.subtitleStreams.compactMap(\.displayTitle).joined(separator: ", ")
                    .text
            }
            .alert(L10n.audio, isPresented: $presentAudioAlert) {
                Button {
                    presentAudioAlert = false
                } label: {
                    L10n.close.text
                }
            } message: {
                viewModel.item.audioStreams.compactMap(\.displayTitle).joined(separator: ", ")
                    .text
            }
        }
    }
}
