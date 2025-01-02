//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct DownloadListView: View {

    @ObservedObject
    var viewModel: DownloadListViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            ForEach(viewModel.items) { item in
                DownloadTaskRow(downloadTask: item)
            }
        }
        .navigationTitle(L10n.downloads)
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension DownloadListView {

    struct DownloadTaskRow: View {

        @EnvironmentObject
        private var router: DownloadListCoordinator.Router

        let downloadTask: DownloadTask

        var body: some View {
            Button {
                router.route(to: \.downloadTask, downloadTask)
            } label: {
                HStack(alignment: .bottom) {
                    ImageView(downloadTask.getImageURL(name: "Primary"))
                        .failure {
                            Color.secondary
                                .opacity(0.8)
                        }
//                        .posterStyle(type: .portrait, width: 60)
                        .posterShadow()

                    VStack(alignment: .leading) {
                        Text(downloadTask.item.displayTitle)
                            .foregroundColor(.primary)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical)

                    Spacer()
                }
            }
        }
    }
}
