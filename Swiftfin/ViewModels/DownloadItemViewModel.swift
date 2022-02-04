//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

final class DownloadItemViewModel: ViewModel {
    
    let itemViewModel: ItemViewModel
    @Published
    var downloadTracker: DownloadTracker?
    @Published
    var downloadProgress: Double = 0
    @Published
    var downloadState: DownloadState = .idle
    
    var hasSpaceForItem: Bool {
        return DownloadManager.main.hasSpace(for: itemViewModel.selectedVideoPlayerViewModel?.fileSize ?? 0)
    }
    
    init(itemViewModel: ItemViewModel) {
        self.itemViewModel = itemViewModel
        
        super.init()
        
        itemViewModel.$downloadTracker
            .sink { newTracker in
                self.downloadTracker = newTracker
                
                self.subscribeTo(tracker: newTracker)
            }
            .store(in: &cancellables)
    }
    
    private func subscribeTo(tracker: DownloadTracker?) {
        guard let tracker = tracker else { return }
        
        tracker.$progress
            .sink(receiveValue: { newProgress in
                self.downloadProgress = newProgress
            })
            .store(in: &cancellables)

        tracker.$state
            .sink(receiveValue: { newState in
                self.downloadState = newState
            })
            .store(in: &cancellables)
    }
    
    func downloadItem() {
        guard hasSpaceForItem else { return }
        
        if let selectedVideoPlayerViewModel = itemViewModel.selectedVideoPlayerViewModel {
            do {
                if DownloadManager.main.hasSpace(for: selectedVideoPlayerViewModel.fileSize ?? 0) {
                    try DownloadManager.main.addDownload(playbackInfo: selectedVideoPlayerViewModel.response,
                                                     item: selectedVideoPlayerViewModel.item,
                                                     fileName: selectedVideoPlayerViewModel.filename ?? "None")
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
