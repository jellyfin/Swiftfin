//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct DownloadItemProgressView: View {
    
    @ObservedObject
    var viewModel: DownloadItemViewModel
    @ObservedObject
    var downloadTracker: DownloadTracker
    
    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Text("Downloading")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(String(format: "%.1f", viewModel.downloadProgress * 100)) %")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            LineProgressBar(value: $viewModel.downloadProgress)
                .frame(height: 15)
            
            switch downloadTracker.state {
            case .idle:
                Button {
                    downloadTracker.start()
                } label: {
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color.jellyfinPurple)
                            .frame(maxWidth: 400, maxHeight: 50)
                            .frame(height: 50)
                            .cornerRadius(10)
                            .padding(.horizontal, 30)
                            .padding([.top, .bottom], 20)

                        Text("Start")
                            .foregroundColor(.white)
                            .bold()
                    }
                }
            case .downloading, .paused:
                Button {
                    downloadTracker.cancel()
                } label: {
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color.red)
                            .frame(maxWidth: 400, maxHeight: 50)
                            .frame(height: 50)
                            .cornerRadius(10)
                            .padding(.horizontal, 30)
                            .padding([.top, .bottom], 20)

                        Text("Cancel")
                            .foregroundColor(.white)
                            .bold()
                    }
                }
            case .cancelled:
                ZStack {
                    Rectangle()
                        .foregroundColor(Color(UIColor.secondarySystemFill))
                        .frame(maxWidth: 400, maxHeight: 50)
                        .frame(height: 50)
                        .cornerRadius(10)
                        .padding(.horizontal, 30)
                        .padding([.top, .bottom], 20)

                    Text("Cancelled")
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .bold()
                }
            case .done:
                ZStack {
                    Rectangle()
                        .foregroundColor(Color.green)
                        .frame(maxWidth: 400, maxHeight: 50)
                        .frame(height: 50)
                        .cornerRadius(10)
                        .padding(.horizontal, 30)
                        .padding([.top, .bottom], 20)

                    Text("Done")
                        .foregroundColor(.white)
                        .bold()
                }
            case .error:
                Text("Error")
                    .foregroundColor(.red)
            }
        }
    }
}
