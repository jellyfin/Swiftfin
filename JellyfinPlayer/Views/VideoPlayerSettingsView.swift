//
//  VideoPlayerSettingsView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/27/21.
//

import Foundation
import UIKit
import SwiftUI
import Combine

enum SettingsChangedEventTypes {
    case subTrackChanged
    case audioTrackChanged
}

struct settingsChangedEvent {
    let eventType: SettingsChangedEventTypes
    let payload: AnyObject
}

protocol VideoPlayerSettingsDelegate: AnyObject {
    func subtitleTrackChanged(newTrackID: Int32)
    func audioTrackChanged(newTrackID: Int32)
    func settingsPopoverDismissed()
}

class SettingsViewDelegate: ObservableObject {

    var subtitlesDidChange = PassthroughSubject<SettingsViewDelegate, Never>()

    var subtitleTrackID: Int32 = 0 {
        didSet {
            self.subtitlesDidChange.send(self)
        }
    }
    
    var audioTrackDidChange = PassthroughSubject<SettingsViewDelegate, Never>()

    var audioTrackID: Int32 = 0 {
        didSet {
            self.audioTrackDidChange.send(self)
        }
    }
    
    var shouldClose = PassthroughSubject<SettingsViewDelegate, Never>()

    var close: Bool = false {
        didSet {
            self.shouldClose.send(self)
        }
    }
}

class VideoPlayerSettingsView: UIViewController {
    private var ctntView: VideoPlayerSettings?
    private var contentViewDelegate: SettingsViewDelegate = SettingsViewDelegate()
    weak var delegate: VideoPlayerSettingsDelegate?
    private var subChangePublisher: AnyCancellable?
    private var audioChangePublisher: AnyCancellable?
    private var shouldClosePublisher: AnyCancellable?
    var subtitles: [Subtitle] = []
    var audioTracks: [AudioTrack] = []
    var currentSubtitleTrack: Int32?
    var currentAudioTrack: Int32?

    override func viewDidLoad() {
        super.viewDidLoad()
        ctntView = VideoPlayerSettings(delegate: self.contentViewDelegate, subtitles: self.subtitles, audioTracks: self.audioTracks, initSub: currentSubtitleTrack ?? -1, initAudio: currentAudioTrack ?? 1)
        let contentView = UIHostingController(rootView: ctntView)
        self.view.addSubview(contentView.view)
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        contentView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        contentView.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        contentView.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        self.subChangePublisher = self.contentViewDelegate.subtitlesDidChange.sink { suiDelegate in
            self.delegate?.subtitleTrackChanged(newTrackID: suiDelegate.subtitleTrackID)
        }
        
        self.audioChangePublisher = self.contentViewDelegate.audioTrackDidChange.sink { suiDelegate in
            self.delegate?.audioTrackChanged(newTrackID: suiDelegate.audioTrackID)
        }
        
        self.shouldClosePublisher = self.contentViewDelegate.shouldClose.sink { suiDelegate in
            if(suiDelegate.close == true) {
                self.delegate?.settingsPopoverDismissed()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
}

struct VideoPlayerSettings: View {
    @ObservedObject var delegate: SettingsViewDelegate
    @State private var subtitles: [Subtitle]
    @State private var audioTracks: [AudioTrack]
    @State private var subtitleSelection: Int32
    @State private var audioTrackSelection: Int32
    
    init(delegate: SettingsViewDelegate, subtitles: [Subtitle], audioTracks: [AudioTrack], initSub: Int32, initAudio: Int32) {
        self.delegate = delegate
        self.subtitles = subtitles
        self.audioTracks = audioTracks
        
        subtitleSelection = initSub
        audioTrackSelection = initAudio
    }
    
    var body: some View {
        Form() {
            if(UIDevice.current.userInterfaceIdiom == .phone) {
                Button {
                    delegate.close = true
                } label: {
                    HStack() {
                        Image(systemName: "chevron.left")
                        Text("Back").font(.callout)
                    }
                }
            }
            Picker("Closed Captions", selection: $subtitleSelection) {
                ForEach(subtitles, id: \.id) { caption in
                    Text(caption.name).tag(caption.id)
                }
            }.onChange(of: subtitleSelection) { id in
                delegate.subtitleTrackID = id
            }
            Picker("Audio Track", selection: $audioTrackSelection) {
                ForEach(audioTracks, id: \.id) { caption in
                    Text(caption.name).tag(caption.id).lineLimit(1)
                }
            }.onChange(of: audioTrackSelection) { id in
                delegate.audioTrackID = id
            }
        }
    }
}
