/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import SwiftUI

class VideoPlayerSettingsView: UINavigationController {
    private var contentView: UIHostingController<VideoPlayerSettings>!
    weak var playerDelegate: PlayerViewController?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            .landscape
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.viewControllers = [UIHostingController(rootView: VideoPlayerSettings(delegate: self.playerDelegate ?? PlayerViewController()))]
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.playerDelegate?.settingsPopoverDismissed()
    }
}

struct VideoPlayerSettings: View {
    weak var delegate: PlayerViewController!
    @State var captionTrack: Int32 = -99
    @State var audioTrack: Int32 = -99
    @State var playbackSpeedSelection: Int = 3

    init(delegate: PlayerViewController) {
        self.delegate = delegate
    }

    var body: some View {
        Form {
            Picker(R.string.localizable.closedCaptions(), selection: $captionTrack) {
                ForEach(delegate.subtitleTrackArray, id: \.id) { caption in
                    Text(caption.name).tag(caption.id)
                }
            }
            .onChange(of: captionTrack) { track in
                self.delegate.subtitleTrackChanged(newTrackID: track)
            }
            Picker(R.string.localizable.audioTrack(), selection: $audioTrack) {
                ForEach(delegate.audioTrackArray, id: \.id) { caption in
                    Text(caption.name).tag(caption.id).lineLimit(1)
                }
            }.onChange(of: audioTrack) { track in
                self.delegate.audioTrackChanged(newTrackID: track)
            }
            Picker(R.string.localizable.playbackSpeed(), selection: $playbackSpeedSelection) {
                ForEach(delegate.playbackSpeeds.indices, id: \.self) { speedIndex in
                    let speed = delegate.playbackSpeeds[speedIndex]
                    Text("\(String(speed))x").tag(speedIndex)
                }
            }
            .onChange(of: playbackSpeedSelection, perform: { index in
                self.delegate.playbackSpeedChanged(index: index)
            })
        }.navigationBarTitleDisplayMode(.inline)
            .navigationTitle(R.string.localizable.audioAndCaptions())
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    Button {
                        self.delegate.settingsPopoverDismissed()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            R.string.localizable.back.text.font(.callout)
                        }
                    }
                }
            }
        }.offset(y: UIDevice.current.userInterfaceIdiom == .pad ? 14 : 0)
        .onAppear(perform: {
            captionTrack = self.delegate.selectedCaptionTrack
            audioTrack = self.delegate.selectedAudioTrack
            playbackSpeedSelection = self.delegate.selectedPlaybackSpeedIndex
        })
    }
}
