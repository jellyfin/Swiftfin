/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import SwiftUI

class VideoPlayerSettingsView: UIViewController {
    private var contentView: UIHostingController<VideoPlayerSettings>!
    weak var delegate: PlayerViewController?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            .landscape
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        contentView = UIHostingController(rootView: VideoPlayerSettings(delegate: self.delegate ?? PlayerViewController()))
        self.view.addSubview(contentView.view)
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        contentView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        contentView.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        contentView.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.delegate?.settingsPopoverDismissed()
    }
}

struct VideoPlayerSettings: View {
    weak var delegate: PlayerViewController!
    @State var captionTrack: Int32 = -99
    @State var audioTrack: Int32 = -99

    init(delegate: PlayerViewController) {
        self.delegate = delegate
    }

    var body: some View {
        NavigationView {
            Form {
                Picker("Closed Captions", selection: $captionTrack) {
                    ForEach(delegate.subtitleTrackArray, id: \.id) { caption in
                        Text(caption.name).tag(caption.id)
                    }
                }
                .onChange(of: captionTrack) { track in
                    self.delegate.subtitleTrackChanged(newTrackID: track)
                }
                Picker("Audio Track", selection: $audioTrack) {
                    ForEach(delegate.audioTrackArray, id: \.id) { caption in
                        Text(caption.name).tag(caption.id).lineLimit(1)
                    }
                }.onChange(of: audioTrack) { track in
                    self.delegate.audioTrackChanged(newTrackID: track)
                }
            }.navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Audio & Captions")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        Button {
                            self.delegate.settingsPopoverDismissed()
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back").font(.callout)
                            }
                        }
                    }
                }
            }
        }.offset(y: UIDevice.current.userInterfaceIdiom == .pad ? 14 : 0)
        .onAppear(perform: {
            _captionTrack.wrappedValue = self.delegate.selectedCaptionTrack
            _audioTrack.wrappedValue = self.delegate.selectedAudioTrack
        })
    }
}
