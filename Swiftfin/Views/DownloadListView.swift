//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Factory
import SwiftUI

struct DownloadListView: View {
    @EnvironmentObject
    private var mainRouter: MainCoordinator.Router

    @ObservedObject
    var viewModel: DownloadListViewModel

    @ObservedObject
    var downloadManager: DownloadManager

    var body: some View {
        ScrollView(showsIndicators: false) {
            ForEach(downloadManager.downloads) { item in
                DownloadTaskRow(downloadManager: downloadManager, downloadTask: item)
                RowDivider()
            }
        }
        .navigationTitle(L10n.downloads)
        .navigationBarTitleDisplayMode(.inline)
        .topBarTrailing {
            SettingsBarButton(
                server: viewModel.userSession.server,
                user: viewModel.userSession.user
            ) {
                mainRouter.route(to: \.settings)
            }
        }
    }
}

extension DownloadListView {
    struct DownloadTaskRow: View {
        @ObservedObject
        var downloadManager: DownloadManager

        @EnvironmentObject
        private var router: DownloadListCoordinator.Router

        let downloadTask: DownloadEntity

        var body: some View {
            Button {
                router.route(to: \.downloadTask, downloadTask)
            } label: {
                HStack(alignment: .center) {
                    ImageView(downloadTask.landscapeImageSources())
                        .failure {
                            Color.secondary
                                .opacity(0.8)
                        }
                        .scaledToFit()
                        .frame(maxWidth: 100)
                        .posterStyle(.landscape)
                        .posterShadow()
                        .padding(.horizontal)

                    Text(downloadTask.item.displayTitle)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)

                    Spacer()
                    Button {
                        downloadManager.remove(task: downloadTask)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .padding(.vertical)
                }
            }
        }
    }
}
