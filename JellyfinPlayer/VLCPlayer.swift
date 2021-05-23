//
//  VideoPlayerView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/10/21.
//

import SwiftUI
import MobileVLCKit

extension NSNotification {
    static let PlayerUpdate = NSNotification.Name.init("PlayerUpdate")
}

enum VideoType {
    case hls;
    case direct;
}

struct PlaybackItem {
    var videoType: VideoType;
    var videoUrl: URL;
    var subtitles: [Subtitle];
}

struct VLCPlayer: UIViewRepresentable{
    var url: Binding<PlaybackItem>;
    var player: Binding<VLCMediaPlayer>;
    var startTime: Int;
    
    func updateUIView(_ uiView: PlayerUIView, context: UIViewRepresentableContext<VLCPlayer>) {
        uiView.url = self.url
        if(self.url.wrappedValue.videoUrl.absoluteString != "https://example.com") {
            uiView.videoSetup()
        }
    }
    
    func makeUIView(context: Context) -> PlayerUIView {
        return PlayerUIView(frame: .zero, url: url, player: self.player, startTime: self.startTime);
    }
}

class PlayerUIView: UIView, VLCMediaPlayerDelegate {
    
    private var mediaPlayer: Binding<VLCMediaPlayer>;
    var url:Binding<PlaybackItem>
    var lastUrl: PlaybackItem?
    var startTime: Int

    init(frame: CGRect, url: Binding<PlaybackItem>, player: Binding<VLCMediaPlayer>, startTime: Int) {
        self.mediaPlayer = player;
        self.url = url;
        self.startTime = startTime;
        super.init(frame: frame)
        mediaPlayer.wrappedValue.delegate = self
        mediaPlayer.wrappedValue.drawable = self
    }
    
    func videoSetup() {
        if(lastUrl == nil || lastUrl?.videoUrl != url.wrappedValue.videoUrl) {
            lastUrl = url.wrappedValue
            mediaPlayer.wrappedValue.stop()
            mediaPlayer.wrappedValue.media = VLCMedia(url: url.wrappedValue.videoUrl)
            self.url.wrappedValue.subtitles.forEach() { sub in
                if(sub.id != -1 && sub.delivery == "External") {
                    mediaPlayer.wrappedValue.addPlaybackSlave(sub.url, type: .subtitle, enforce: false)
                }
            }
            
            mediaPlayer.wrappedValue.perform(Selector(("setTextRendererFontSize:")), with: 14)
            //mediaPlayer.wrappedValue.perform(Selector(("setTextRendererFont:")), with: "Copperplate")
            
            DispatchQueue.global(qos: .utility).async { [weak self] in
                if(self?.url.wrappedValue.videoType ?? .hls == .hls) {
                    usleep(75000000)
                }
                self?.mediaPlayer.wrappedValue.play()
                if(self?.startTime != 0) {
                    print(self?.startTime ?? "")
                    self?.mediaPlayer.wrappedValue.jumpForward(Int32(self!.startTime/10000000))
                }
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
