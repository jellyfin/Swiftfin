//
//  PlayerDemo.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/10/21.
//

import SwiftUI
import SwiftyJSON
import SwiftyRequest
import AVKit
import MobileVLCKit

struct Subtitle {
    var name: String;
    var id: Int32;
    var url: URL;
    var delivery: String;
}

extension String {
    public func leftPad(toWidth width: Int, withString string: String?) -> String {
        let paddingString = string ?? " "

        if self.count >= width {
            return self
        }

        let remainingLength: Int = width - self.count
        var padString = String()
        for _ in 0 ..< remainingLength {
            padString += paddingString
        }

        return "\(padString)\(self)"
    }

}
struct PlayerDemo: View {
    @EnvironmentObject var globalData: GlobalData
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var item: DetailItem;
    @State private var pbitem: PlaybackItem = PlaybackItem(videoType: VideoType.direct, videoUrl: URL(string: "https://example.com")!, subtitles: []);
    @State private var streamLoading = false;
    @State private var vlcplayer: VLCMediaPlayer = VLCMediaPlayer(options: ["-vv", "--sub-margin=-50"]);
    @State private var isPlaying = false;
    @State private var subtitles: [Subtitle] = [];
    @State private var inactivity: Bool = true;
    @State private var lastActivityTime: Double = 0;
    @State private var scrub: Double = 0;
    @State private var timeText: String = "-:--:--";
    @State private var playPauseButtonSystemName: String = "pause";
    @State private var playSessionId: String = "";
    @State private var lastPosition: Double = 0;
    @State private var iterations: Int = 0;
    @State private var captionConfiguration: Bool = false {
        didSet {
            if(captionConfiguration == false) {
                DispatchQueue.global(qos: .userInitiated).async { [self] in
                    vlcplayer.pause()
                    usleep(10000);
                    vlcplayer.play()
                    usleep(10000);
                    vlcplayer.pause()
                    usleep(10000);
                    vlcplayer.play()
                }
            }
        }
    };
    @State private var selectedCaptionTrack: Int32 = -1;
    var playing: Binding<Bool>;
    
    init(item: DetailItem, playing: Binding<Bool>) {
        self.item = item;
        self.playing = playing;
    }
    
    @State var lastProgressReportSent: Double = CACurrentMediaTime()
    
    func keepUpWithPlayerState() {
        if(!vlcplayer.isPlaying) {
            while(!vlcplayer.isPlaying) {}
        }
        while(vlcplayer.state != VLCMediaPlayerState.stopped) {
            _streamLoading.wrappedValue = false;
            while(vlcplayer.isPlaying) {
                vlcplayer.currentVideoSubTitleIndex = _selectedCaptionTrack.wrappedValue;
                usleep(500000)
                if(CACurrentMediaTime() - lastProgressReportSent > 10) {
                    sendProgressReport()
                    _lastProgressReportSent.wrappedValue = CACurrentMediaTime()
                }
                if(vlcplayer.time.intValue != 0) {
                    _scrub.wrappedValue = Double(Double(vlcplayer.time.intValue) / Double(vlcplayer.time.intValue + abs(vlcplayer.remainingTime.intValue)));
                    
                    //Turn remainingTime into text
                    let remainingTime = abs(vlcplayer.remainingTime.intValue)/1000;
                    let hours = remainingTime / 3600;
                    let minutes = (remainingTime % 3600) / 60;
                    let seconds = (remainingTime % 3600) % 60;
                    if(hours != 0) {
                        timeText = "\(Int(hours)):\(String(Int((minutes))).leftPad(toWidth: 2, withString: "0")):\(String(Int((seconds))).leftPad(toWidth: 2, withString: "0"))";
                    } else {
                        timeText = "\(String(Int((minutes))).leftPad(toWidth: 2, withString: "0")):\(String(Int((seconds))).leftPad(toWidth: 2, withString: "0"))";
                    }
                }
                if(CACurrentMediaTime() - _lastActivityTime.wrappedValue > 5 && vlcplayer.state != VLCMediaPlayerState.paused) {
                    _inactivity.wrappedValue = true
                }
                if((lastPosition == Double(vlcplayer.position) && vlcplayer.state != VLCMediaPlayerState.paused)) {
                    if(iterations > 5) {
                        _iterations.wrappedValue = 0;
                        _streamLoading.wrappedValue = true;
                    }
                    _iterations.wrappedValue+=1;
                } else {
                    _iterations.wrappedValue = 0;
                    _streamLoading.wrappedValue = false;
                }
                if(vlcplayer.state == VLCMediaPlayerState.error) {
                    playing.wrappedValue = false;
                }
                _lastPosition.wrappedValue = Double(vlcplayer.position)
            }
        }
    }
    
    func sendProgressReport() {
        var progressBody: String = "";
        if(pbitem.videoType == VideoType.direct) {
            progressBody  = "{\"VolumeLevel\":100,\"IsMuted\":false,\"IsPaused\":\(vlcplayer.state == VLCMediaPlayerState.paused ? "true" : "false"),\"RepeatMode\":\"RepeatNone\",\"ShuffleMode\":\"Sorted\",\"MaxStreamingBitrate\":140000000,\"PositionTicks\":\(Int(vlcplayer.position * Float(item.RuntimeTicks))),\"PlaybackStartTimeTicks\":16209515560670000,\"AudioStreamIndex\":1,\"BufferedRanges\":[{\"start\":0,\"end\":569735888.888889}],\"PlayMethod\":\"\(pbitem.videoType == VideoType.direct ? "DirectStream" : "Transcode")\",\"PlaySessionId\":\"\(playSessionId)\",\"PlaylistItemId\":\"playlistItem1\",\"MediaSourceId\":\"\(item.Id)\",\"CanSeek\":true,\"ItemId\":\"\(item.Id)\",\"EventName\":\"timeupdate\"}";
        } else {
            progressBody  = "{\"VolumeLevel\":100,\"IsMuted\":false,\"IsPaused\":\(vlcplayer.state == VLCMediaPlayerState.paused ? "true" : "false"),\"RepeatMode\":\"RepeatNone\",\"ShuffleMode\":\"Sorted\",\"MaxStreamingBitrate\":140000000,\"PositionTicks\":\(Int(vlcplayer.position * Float(item.RuntimeTicks))),\"PlaybackStartTimeTicks\":16209515560670000,\"AudioStreamIndex\":1,\"BufferedRanges\":[{\"start\":0,\"end\":569735888.888889}],\"PlayMethod\":\"Transcode\",\"PlaySessionId\":\"\(playSessionId)\",\"PlaylistItemId\":\"playlistItem1\",\"MediaSourceId\":\"\(item.Id)\",\"CanSeek\":true,\"ItemId\":\"\(item.Id)\",\"EventName\":\"timeupdate\"}";
        }
        
        let request = RestRequest(method: .post, url: (globalData.server?.baseURI ?? "") + "/Sessions/Playing/Progress")
        request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
        request.contentType = "application/json"
        request.acceptType = "application/json"
        request.messageBody = progressBody.data(using: .ascii);
        request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
            switch result {
            case .success(let response):
                let body = response.body
                print(body)
                break
            case .failure(let error):
                debugPrint(error)
                break
            }
        }
    }
    
    func sendStopReport() {
        var progressBody: String = "";
        if(pbitem.videoType == VideoType.direct) {
            progressBody  = "{\"VolumeLevel\":100,\"IsMuted\":false,\"IsPaused\":true,\"RepeatMode\":\"RepeatNone\",\"ShuffleMode\":\"Sorted\",\"MaxStreamingBitrate\":140000000,\"PositionTicks\":\(Int(vlcplayer.position * Float(item.RuntimeTicks))),\"PlaybackStartTimeTicks\":16209515560670000,\"AudioStreamIndex\":1,\"BufferedRanges\":[],\"PlayMethod\":\"\(pbitem.videoType == VideoType.direct ? "DirectStream" : "Transcode")\",\"PlaySessionId\":\"\(playSessionId)\",\"PlaylistItemId\":\"playlistItem1\",\"MediaSourceId\":\"\(item.Id)\",\"CanSeek\":true,\"ItemId\":\"\(item.Id)\",\"NowPlayingQueue\":[{\"Id\":\"\(item.Id)\",\"PlaylistItemId\":\"playlistItem1\"}]}";
        } else {
            progressBody  = "{\"VolumeLevel\":100,\"IsMuted\":false,\"IsPaused\":true,\"RepeatMode\":\"RepeatNone\",\"ShuffleMode\":\"Sorted\",\"MaxStreamingBitrate\":140000000,\"PositionTicks\":\(Int(vlcplayer.position * Float(item.RuntimeTicks))),\"PlaybackStartTimeTicks\":16209515560670000,\"AudioStreamIndex\":1,\"BufferedRanges\":[{\"start\":0,\"end\":100000}],\"PlayMethod\":\"Transcode\",\"PlaySessionId\":\"\(playSessionId)\",\"PlaylistItemId\":\"playlistItem1\",\"MediaSourceId\":\"\(item.Id)\",\"CanSeek\":true,\"ItemId\":\"\(item.Id)\",\"NowPlayingQueue\":[{\"Id\":\"\(item.Id)\",\"PlaylistItemId\":\"playlistItem1\"}]}";
        }
        
        let request = RestRequest(method: .post, url: (globalData.server?.baseURI ?? "") + "/Sessions/Playing/Stopped")
        request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
        request.contentType = "application/json"
        request.acceptType = "application/json"
        request.messageBody = progressBody.data(using: .ascii);
        request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
            switch result {
            case .success(let response):
                let body = response.body
                print(body)
                break
            case .failure(let error):
                debugPrint(error)
                break
            }
        }
    }
    
    func sendPlayReport() {
        var progressBody: String = "";
        if(pbitem.videoType == VideoType.hls) {
            progressBody  = "{\"VolumeLevel\":100,\"IsMuted\":false,\"IsPaused\":false,\"RepeatMode\":\"RepeatNone\",\"ShuffleMode\":\"Sorted\",\"MaxStreamingBitrate\":140000000,\"PositionTicks\":0,\"PlaybackStartTimeTicks\":16209515560670000,\"AudioStreamIndex\":1,\"BufferedRanges\":[],\"PlayMethod\":\"Transcode\",\"PlaySessionId\":\"\(playSessionId)\",\"PlaylistItemId\":\"playlistItem1\",\"MediaSourceId\":\"\(item.Id)\",\"CanSeek\":true,\"ItemId\":\"\(item.Id)\",\"NowPlayingQueue\":[{\"Id\":\"\(item.Id)\",\"PlaylistItemId\":\"playlistItem1\"}]}";
        } else {
            progressBody  = "{\"VolumeLevel\":100,\"IsMuted\":false,\"IsPaused\":false,\"RepeatMode\":\"RepeatNone\",\"ShuffleMode\":\"Sorted\",\"MaxStreamingBitrate\":140000000,\"PositionTicks\":0,\"PlaybackStartTimeTicks\":16209515560670000,\"AudioStreamIndex\":1,\"BufferedRanges\":[],\"PlayMethod\":\"Transcode\",\"PlaySessionId\":\"\(playSessionId)\",\"PlaylistItemId\":\"playlistItem1\",\"MediaSourceId\":\"\(item.Id)\",\"CanSeek\":true,\"ItemId\":\"\(item.Id)\",\"NowPlayingQueue\":[{\"Id\":\"\(item.Id)\",\"PlaylistItemId\":\"playlistItem1\"}]}";
        }
        
        let request = RestRequest(method: .post, url: (globalData.server?.baseURI ?? "") + "/Sessions/Playing")
        request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
        request.contentType = "application/json"
        request.acceptType = "application/json"
        request.messageBody = progressBody.data(using: .ascii);
        request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
            switch result {
            case .success(let response):
                let body = response.body
                print(body)
                break
            case .failure(let error):
                debugPrint(error)
                break
            }
        }
    }
    
    func startStream() {
        _streamLoading.wrappedValue = true;
        let request = RestRequest(method: .post, url: (globalData.server?.baseURI ?? "") + "/Items/\(item.Id)/PlaybackInfo?UserId=\(globalData.user?.user_id ?? "")&StartTimeTicks=0&IsPlayback=true&AutoOpenLiveStream=true&MaxStreamingBitrate=70000000")
        request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
        request.contentType = "application/json"
        request.acceptType = "application/json"
        request.messageBody = "{\"DeviceProfile\":{\"MaxStreamingBitrate\":70000000,\"MaxStaticBitrate\":700000000,\"MusicStreamingTranscodingBitrate\":384000,\"DirectPlayProfiles\":[{\"Container\":\"webm\",\"Type\":\"Video\",\"VideoCodec\":\"vp8\",\"AudioCodec\":\"vorbis\"},{\"Container\":\"mp4,m4v,mkv,mov\",\"Type\":\"Video\",\"VideoCodec\":\"hevc,h264,vp8,dvhe,dva1,dvh1\",\"AudioCodec\":\"aac,mp3,ac3,eac3,flac,alac,vorbis,dts\"},{\"Container\":\"mp3\",\"Type\":\"Audio\"},{\"Container\":\"aac\",\"Type\":\"Audio\"},{\"Container\":\"m4a\",\"AudioCodec\":\"aac\",\"Type\":\"Audio\"},{\"Container\":\"m4b\",\"AudioCodec\":\"aac\",\"Type\":\"Audio\"},{\"Container\":\"flac\",\"Type\":\"Audio\"},{\"Container\":\"alac\",\"Type\":\"Audio\"},{\"Container\":\"m4a\",\"AudioCodec\":\"alac\",\"Type\":\"Audio\"},{\"Container\":\"m4b\",\"AudioCodec\":\"alac\",\"Type\":\"Audio\"},{\"Container\":\"webma\",\"Type\":\"Audio\"},{\"Container\":\"webm\",\"AudioCodec\":\"webma\",\"Type\":\"Audio\"},{\"Container\":\"wav\",\"Type\":\"Audio\"}],\"TranscodingProfiles\":[{\"Container\":\"aac\",\"Type\":\"Audio\",\"AudioCodec\":\"aac\",\"Context\":\"Streaming\",\"Protocol\":\"hls\",\"MaxAudioChannels\":\"6\",\"MinSegments\":\"2\",\"BreakOnNonKeyFrames\":true},{\"Container\":\"aac\",\"Type\":\"Audio\",\"AudioCodec\":\"aac\",\"Context\":\"Streaming\",\"Protocol\":\"http\",\"MaxAudioChannels\":\"6\"},{\"Container\":\"mp3\",\"Type\":\"Audio\",\"AudioCodec\":\"mp3\",\"Context\":\"Streaming\",\"Protocol\":\"http\",\"MaxAudioChannels\":\"6\"},{\"Container\":\"wav\",\"Type\":\"Audio\",\"AudioCodec\":\"wav\",\"Context\":\"Streaming\",\"Protocol\":\"http\",\"MaxAudioChannels\":\"6\"},{\"Container\":\"mp3\",\"Type\":\"Audio\",\"AudioCodec\":\"mp3\",\"Context\":\"Static\",\"Protocol\":\"http\",\"MaxAudioChannels\":\"6\"},{\"Container\":\"aac\",\"Type\":\"Audio\",\"AudioCodec\":\"aac\",\"Context\":\"Static\",\"Protocol\":\"http\",\"MaxAudioChannels\":\"6\"},{\"Container\":\"wav\",\"Type\":\"Audio\",\"AudioCodec\":\"wav\",\"Context\":\"Static\",\"Protocol\":\"http\",\"MaxAudioChannels\":\"6\"},{\"Container\":\"ts\",\"Type\":\"Video\",\"AudioCodec\":\"aac,mp3,ac3,eac3\",\"VideoCodec\":\"h264,hevc\",\"Context\":\"Streaming\",\"Protocol\":\"hls\",\"MaxAudioChannels\":\"6\",\"MinSegments\":\"2\",\"BreakOnNonKeyFrames\":true},{\"Container\":\"webm\",\"Type\":\"Video\",\"AudioCodec\":\"vorbis\",\"VideoCodec\":\"vpx\",\"Context\":\"Streaming\",\"Protocol\":\"http\",\"MaxAudioChannels\":\"6\"},{\"Container\":\"mp4\",\"Type\":\"Video\",\"AudioCodec\":\"aac,mp3,ac3,eac3,flac,alac,vorbis\",\"VideoCodec\":\"h264,hevc\",\"Context\":\"Static\",\"Protocol\":\"http\"}],\"ContainerProfiles\":[],\"CodecProfiles\":[{\"Type\":\"Video\",\"Codec\":\"h264\",\"Conditions\":[{\"Condition\":\"NotEquals\",\"Property\":\"IsAnamorphic\",\"Value\":\"true\",\"IsRequired\":false},{\"Condition\":\"EqualsAny\",\"Property\":\"VideoProfile\",\"Value\":\"high|main|baseline|constrained baseline\",\"IsRequired\":false},{\"Condition\":\"LessThanEqual\",\"Property\":\"VideoLevel\",\"Value\":\"80\",\"IsRequired\":false},{\"Condition\":\"NotEquals\",\"Property\":\"IsInterlaced\",\"Value\":\"true\",\"IsRequired\":false}]},{\"Type\":\"Video\",\"Codec\":\"hevc\",\"Conditions\":[{\"Condition\":\"NotEquals\",\"Property\":\"IsAnamorphic\",\"Value\":\"true\",\"IsRequired\":false},{\"Condition\":\"EqualsAny\",\"Property\":\"VideoProfile\",\"Value\":\"main|main 10\",\"IsRequired\":false},{\"Condition\":\"LessThanEqual\",\"Property\":\"VideoLevel\",\"Value\":\"190\",\"IsRequired\":false},{\"Condition\":\"NotEquals\",\"Property\":\"IsInterlaced\",\"Value\":\"true\",\"IsRequired\":false}]}],\"SubtitleProfiles\":[{\"Format\":\"vtt\",\"Method\":\"External\"},{\"Format\":\"ass\",\"Method\":\"External\"},{\"Format\":\"ssa\",\"Method\":\"External\"},{\"Format\":\"pgssub\",\"Method\":\"Embed\"},{\"Format\":\"pgs\",\"Method\":\"Embed\"},{\"Format\":\"sub\",\"Method\":\"Embed\"}],\"ResponseProfiles\":[{\"Type\":\"Video\",\"Container\":\"m4v\",\"MimeType\":\"video/mp4\"}]}}".data(using: .ascii);
         
        request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
            switch result {
            case .success(let response):
                let body = response.body
                do {
                    let json = try JSON(data: body)
                    _playSessionId.wrappedValue = json["PlaySessionId"].string ?? "";
                    if(json["MediaSources"][0]["TranscodingUrl"].string != nil) {
                        //Video is transcoded due to TranscodingReason - also may just be remuxed
                        for (_,stream):(String, JSON) in json["MediaSources"][0]["MediaStreams"] {
                            if(stream["Type"].string == "Subtitle") {
                                print("Found subtitle track: \(stream["DeliveryUrl"].string ?? "")")
                            }
                        }
                        let streamURL: URL = URL(string: "\(globalData.server?.baseURI ?? "")\((json["MediaSources"][0]["TranscodingUrl"].string ?? "").replacingOccurrences(of: "master.m3u8", with: "main.m3u8"))")!
                        print(streamURL);
                        let item = PlaybackItem(videoType: VideoType.hls, videoUrl: streamURL, subtitles: [])
                        let disableSubtitleTrack = Subtitle(name: "Disabled", id: -1, url: URL(string: "https://example.com")!, delivery: "Embed")
                        _subtitles.wrappedValue.append(disableSubtitleTrack);
                        for (_,stream):(String, JSON) in json["MediaSources"][0]["MediaStreams"] {
                            if(stream["Type"].string == "Subtitle") {
                                let deliveryUrl = URL(string: "\(globalData.server?.baseURI ?? "")\(stream["DeliveryUrl"].string ?? "")")!
                                let subtitle = Subtitle(name: stream["DisplayTitle"].string ?? "", id: Int32(stream["Index"].int ?? 0), url: deliveryUrl, delivery: stream["DeliveryMethod"].string ?? "")
                                _subtitles.wrappedValue.append(subtitle);
                            }
                        }
                        sendPlayReport();
                        pbitem = item;
                        pbitem.subtitles = subtitles;
                        _isPlaying.wrappedValue = true;
                    } else {
                        print("Direct play of item \(item.Name)")
                        let streamURL: URL = URL(string: "\(globalData.server?.baseURI ?? "")/Videos/\(item.Id)/stream?Static=true&mediaSourceId=\(item.Id)&deviceId=\(globalData.user?.device_uuid ?? "")&api_key=\(globalData.authToken)&Tag=\(json["MediaSources"][0]["ETag"])")!;
                        let item = PlaybackItem(videoType: VideoType.direct, videoUrl: streamURL, subtitles: [])
                        let disableSubtitleTrack = Subtitle(name: "Disabled", id: -1, url: URL(string: "https://example.com")!, delivery: "Embed")
                        _subtitles.wrappedValue.append(disableSubtitleTrack);
                        for (_,stream):(String, JSON) in json["MediaSources"][0]["MediaStreams"] {
                            if(stream["Type"].string == "Subtitle") {
                                print("Found subtitle track with title \(stream["DisplayTitle"].string ?? "") Delivery method: \(stream["DeliveryMethod"].string ?? "")")
                                let deliveryUrl = URL(string: "\(globalData.server?.baseURI ?? "")\(stream["DeliveryUrl"].string ?? "")")!
                                let subtitle = Subtitle(name: stream["DisplayTitle"].string ?? "", id: Int32(stream["Index"].int ?? 0), url: deliveryUrl, delivery: stream["DeliveryMethod"].string ?? "")
                                _subtitles.wrappedValue.append(subtitle);
                            }
                        }
                        pbitem = item;
                        pbitem.subtitles = subtitles;
                        _isPlaying.wrappedValue = true;
                    }
                    DispatchQueue.global(qos: .userInitiated).async { [self] in
                        self.keepUpWithPlayerState()
                    }
                } catch {
                    
                }
                break
            case .failure(let error):
                debugPrint(error)
                break
            }
        }
    }
    
    func processScrubbingState() {
        let videoDuration = Double(vlcplayer.time.intValue + abs(vlcplayer.remainingTime.intValue))/1000
        while(vlcplayer.state != VLCMediaPlayerState.paused) {}
        while(vlcplayer.state == VLCMediaPlayerState.paused) {
            let secondsScrubbedTo = round(_scrub.wrappedValue * videoDuration);
            let scrubRemaining = videoDuration - secondsScrubbedTo;
            usleep(10000)
            
            let remainingTime = scrubRemaining;
            let hours = floor(remainingTime / 3600);
            let minutes = (remainingTime.truncatingRemainder(dividingBy: 3600)) / 60;
            let seconds = (remainingTime.truncatingRemainder(dividingBy: 3600)).truncatingRemainder(dividingBy: 60);
            if(hours != 0) {
                timeText = "\(Int(hours)):\(String(Int(floor(minutes))).leftPad(toWidth: 2, withString: "0")):\(String(Int(floor(seconds))).leftPad(toWidth: 2, withString: "0"))";
            } else {
                timeText = "\(String(Int(floor(minutes))).leftPad(toWidth: 2, withString: "0")):\(String(Int(floor(seconds))).leftPad(toWidth: 2, withString: "0"))";
            }
        }
    }
    
    func resetTimer() {
        if(_inactivity.wrappedValue == false) {
            _inactivity.wrappedValue = true;
            return;
        }
        _lastActivityTime.wrappedValue = CACurrentMediaTime()
        _inactivity.wrappedValue = false;
    }
    
    var body: some View {
        LoadingView(isShowing: ($streamLoading)) {
            ZStack() {
                VLCPlayer(url: $pbitem, player: $vlcplayer, startTime: Int(item.Progress)).onDisappear(perform: {
                    _isPlaying.wrappedValue = false;
                    vlcplayer.stop()
                })
                VStack() {
                    HStack() {
                        HStack() {
                            Button() {
                                self.playing.wrappedValue = false;
                            } label: {
                                HStack() {
                                    Image(systemName: "chevron.left").font(.system(size: 20)).foregroundColor(.white)
                                }
                            }.frame(width: 20)
                            Spacer()
                            Text(item.Name).font(.headline).fontWeight(.semibold).foregroundColor(.white).offset(x:-4)
                            Spacer()
                            Button() {
                                vlcplayer.pause()
                                self.captionConfiguration = true;
                            } label: {
                                HStack() {
                                    Image(systemName: "captions.bubble").font(.system(size: 20)).foregroundColor(.white)
                                }
                            }.frame(width: 20)
                        }
                        Spacer()
                    }.padding(EdgeInsets(top: 55, leading: 40, bottom: 0, trailing: 40))
                    Spacer()
                    HStack() {
                        Spacer()
                        Button() {
                            vlcplayer.jumpBackward(15)
                        } label: {
                            Image(systemName: "gobackward.15").font(.system(size: 40)).foregroundColor(.white)
                        }.padding(20)
                        Spacer()
                        Button() {
                            if(vlcplayer.state != VLCMediaPlayerState.paused) {
                                vlcplayer.pause()
                                playPauseButtonSystemName = "play"
                                sendProgressReport()
                            } else {
                                vlcplayer.play()
                                playPauseButtonSystemName = "pause"
                                sendProgressReport()
                            }
                        } label: {
                            Image(systemName: playPauseButtonSystemName).font(.system(size: 55)).foregroundColor(.white)
                        }.padding(20)
                        Spacer()
                        Button() {
                            vlcplayer.jumpForward(15)
                        } label: {
                            Image(systemName: "goforward.15").font(.system(size: 40)).foregroundColor(.white)
                        }.padding(20)
                        Spacer()
                    }.padding(.leading, -20)
                    Spacer()
                    HStack() {
                        Slider(value: $scrub, onEditingChanged: { bool in
                            let videoPosition = Double(vlcplayer.time.intValue)
                            let videoDuration = Double(vlcplayer.time.intValue + abs(vlcplayer.remainingTime.intValue))
                            if(bool == true) {
                                vlcplayer.pause()
                                DispatchQueue.global(qos: .userInitiated).async { [self] in
                                    self.processScrubbingState()
                                }
                            } else {
                                //Scrub is value from 0..1 - find position in video and add / or remove.
                                let secondsScrubbedTo = round(_scrub.wrappedValue * videoDuration);
                                let offset = secondsScrubbedTo - videoPosition;
                                sendProgressReport()
                                vlcplayer.play()
                                if(offset > 0) {
                                    vlcplayer.jumpForward(Int32(offset)/1000);
                                } else {
                                    vlcplayer.jumpBackward(Int32(abs(offset))/1000);
                                }
                            }
                        })
                        .accentColor(Color(red: 172/255, green: 92/255, blue: 195/255))
                        Text(timeText).fontWeight(.semibold).frame(width: 80).foregroundColor(.white)
                    }.padding(EdgeInsets(top: -20, leading: 44, bottom: 42, trailing: 40))
                }.transition(.fade)
                .padding(EdgeInsets(top: 0, leading: -30, bottom: 0, trailing: -30))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.black).opacity(0.4))
                .isHidden(inactivity)
            }.padding(EdgeInsets(top: 0, leading: 34, bottom: 0, trailing: 34))
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .onAppear(perform: startStream)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .statusBar(hidden: true)
        .introspectTabBarController { (UITabBarController) in
            UITabBarController.tabBar.isHidden = true
        }
        .prefersHomeIndicatorAutoHidden(true)
        .supportedOrientations(.landscapeRight)
        .edgesIgnoringSafeArea(.all)
        .onTapGesture(perform: resetTimer)
        .overrideViewPreference(.dark)
        .popover( isPresented: self.$captionConfiguration, arrowEdge: .bottom) {
            NavigationView() {
                VStack() {
                    Form() {
                        Picker("Closed Captions", selection: $selectedCaptionTrack) {
                            ForEach(subtitles, id: \.id) { caption in
                                Text(caption.name).tag(caption.id)
                            }
                        }.onChange(of: selectedCaptionTrack) { track in
                            vlcplayer.currentVideoSubTitleIndex = track;
                        }
                    }
                    Text("Subtitles may take a few moments to appear once selected.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .navigationBarTitle("Audio & Captions", displayMode: .inline)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            captionConfiguration = false;
                            playPauseButtonSystemName = "pause";
                        } label: {
                            HStack() {
                                Text("Back").font(.callout)
                            }
                        }
                    }
                }
            }.edgesIgnoringSafeArea(.bottom)
        }
    }
}
