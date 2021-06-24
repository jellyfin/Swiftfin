//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI

class AudioViewController: UIViewController {
    
    var height : CGFloat = 420

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarItem.title = "Audio"
        
    }
    
    func prepareAudioView(audioTracks: [AudioTrack], selectedTrack: Int32, delegate: VideoPlayerSettingsDelegate)
    {
        let contentView = UIHostingController(rootView: AudioView(selectedTrack: selectedTrack, audioTrackArray: audioTracks, delegate: delegate))
        self.view.addSubview(contentView.view)
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        contentView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        contentView.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        contentView.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
    }

}

struct AudioView: View {
    
    @State var selectedTrack : Int32 = -1
    @State var audioTrackArray: [AudioTrack] = []
    
    weak var delegate: VideoPlayerSettingsDelegate?

    var body : some View {
        NavigationView {
            VStack() {
                List(audioTrackArray, id: \.id) { track in
                    Button(action: {
                        delegate?.selectNew(audioTrack: track.id)
                        selectedTrack = track.id
                    }, label: {
                        HStack(spacing: 10){
                            if track.id == selectedTrack {
                                Image(systemName: "checkmark")
                            }
                            else {
                                Image(systemName: "checkmark")
                                    .hidden()
                            }
                            Text(track.name)
                        }
                    })
                    
                }
            }
            .frame(width: 400)
            .frame(maxHeight: 400)
        }
    }
}
