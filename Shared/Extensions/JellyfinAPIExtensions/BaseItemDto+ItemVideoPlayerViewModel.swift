//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import JellyfinAPI
import VLCUI

class ItemVideoPlayerViewModel: ObservableObject, VLCVideoPlayerDelegate {
    
    @Published
    var currentPlayerTicks: Int32 = 0
    
    var playerDidInitiallyPlay = false
    
    var eventSubject: CurrentValueSubject<VLCVideoPlayer.Event?, Never> = .init(nil)
    
    let playbackURL: URL
    let item: BaseItemDto
    
    init(playbackURL: URL, item: BaseItemDto) {
        self.playbackURL = playbackURL
        self.item = item
    }
    
    func jump(to ticks: Int32) {
        eventSubject.send(.setTicks(ticks))
    }
    
    func vlcVideoPlayer(didUpdateTicks ticks: Int32, with playbackInformation: VLCVideoPlayer.PlaybackInformation) {
        self.currentPlayerTicks = ticks
    }
    
    func vlcVideoPlayer(didUpdateState state: VLCVideoPlayer.State) {
        print("new state: \(state)")
        if state == .playing, !playerDidInitiallyPlay {
            jumpToResume()
            playerDidInitiallyPlay = true
        }
    }
    
    private func jumpToResume() {
        guard let playbackPositionTicks = item.userData?.playbackPositionTicks,
              playbackPositionTicks > 0 else { return }
        let a = Int32(playbackPositionTicks / 10_000)
        print("Resume ticks: \(a)")
        jump(to: a)
    }
}

extension BaseItemDto {
    
    func createItemVideoPlayerViewModel() -> AnyPublisher<[ItemVideoPlayerViewModel], Error> {
        
        let builder = DeviceProfileBuilder()
        // TODO: fix bitrate settings
        let tempOverkillBitrate = 360_000_000
        builder.setMaxBitrate(bitrate: tempOverkillBitrate)
        let profile = builder.buildProfile()
        
        let playbackInfoRequest = GetPostedPlaybackInfoRequest(
            userId: SessionManager.main.currentLogin.user.id,
            maxStreamingBitrate: tempOverkillBitrate
        )
        
        return MediaInfoAPI.getPostedPlaybackInfo(
            itemId: self.id!,
            userId: SessionManager.main.currentLogin.user.id,
            maxStreamingBitrate: tempOverkillBitrate,
            getPostedPlaybackInfoRequest: playbackInfoRequest
        )
        .map { response in
            response.mediaSources!.map { $0.itemVideoPlayerViewModel(with: self, playSessionID: response.playSessionId!) }
        }
        .eraseToAnyPublisher()
    }
}
