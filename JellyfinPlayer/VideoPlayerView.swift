//
//  VideoPlayerView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/10/21.
//

import SwiftUI
import SwiftyJSON
import SwiftyRequest
import AVKit
import MobileVLCKit
import Foundation
import NotificationCenter

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

struct VideoPlayerView: View {
    @EnvironmentObject var globalData: GlobalData
    var item: DetailItem;
    @State private var pbitem: PlaybackItem = PlaybackItem(videoType: VideoType.direct, videoUrl: URL(string: "https://example.com")!, subtitles: []);
    @State private var streamLoading = false;
    @State private var vlcplayer: VLCMediaPlayer = VLCMediaPlayer(options: ["--sub-margin=-50"]);
    @State private var isPlaying = false;
    @State private var subtitles: [Subtitle] = [];
    @State private var audioTracks: [Subtitle] = [];
    @State private var inactivity: Bool = true;
    @State private var lastActivityTime: Double = 0;
    @State private var scrub: Double = 0;
    @State private var timeText: String = "-:--:--";
    @State private var playPauseButtonSystemName: String = "pause";
    @State private var playSessionId: String = "";
    @State private var lastPosition: Double = 0;
    @State private var iterations: Int = 0;
    @State private var startTime: Int = 0;
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
    @State private var selectedAudioTrack: Int32 = -1;
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
        sendProgressReport(eventName: "unpause")
        while(vlcplayer.state != VLCMediaPlayerState.stopped) {
            _streamLoading.wrappedValue = false;
            while(vlcplayer.isPlaying) {
                vlcplayer.currentVideoSubTitleIndex = _selectedCaptionTrack.wrappedValue;
                usleep(500000)
                if(CACurrentMediaTime() - lastProgressReportSent > 10) {
                    sendProgressReport(eventName: "timeupdate")
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
    
    func sendProgressReport(eventName: String) {
        var progressBody: String = "";
        if(pbitem.videoType == VideoType.direct) {
            progressBody  = "{\"VolumeLevel\":100,\"IsMuted\":false,\"IsPaused\":\(vlcplayer.state == VLCMediaPlayerState.paused ? "true" : "false"),\"RepeatMode\":\"RepeatNone\",\"ShuffleMode\":\"Sorted\",\"MaxStreamingBitrate\":120000000,\"PositionTicks\":\(Int(vlcplayer.position * Float(item.RuntimeTicks))),\"PlaybackStartTimeTicks\":\(startTime),\"AudioStreamIndex\":\(selectedAudioTrack),\"BufferedRanges\":[{\"start\":0,\"end\":569735888.888889}],\"PlayMethod\":\"DirectStream\",\"PlaySessionId\":\"\(playSessionId)\",\"PlaylistItemId\":\"playlistItem0\",\"MediaSourceId\":\"\(item.Id)\",\"CanSeek\":true,\"ItemId\":\"\(item.Id)\",\"EventName\":\"\(eventName)\"}";
        } else {
            progressBody  = "{\"VolumeLevel\":100,\"IsMuted\":false,\"IsPaused\":\(vlcplayer.state == VLCMediaPlayerState.paused ? "true" : "false"),\"RepeatMode\":\"RepeatNone\",\"ShuffleMode\":\"Sorted\",\"MaxStreamingBitrate\":120000000,\"PositionTicks\":\(Int(vlcplayer.position * Float(item.RuntimeTicks))),\"PlaybackStartTimeTicks\":\(startTime),\"AudioStreamIndex\":\(selectedAudioTrack),\"BufferedRanges\":[{\"start\":0,\"end\":569735888.888889}],\"PlayMethod\":\"Transcode\",\"PlaySessionId\":\"\(playSessionId)\",\"PlaylistItemId\":\"playlistItem0\",\"MediaSourceId\":\"\(item.Id)\",\"CanSeek\":true,\"ItemId\":\"\(item.Id)\",\"EventName\":\"\(eventName)\"}";
        }
        
        let request = RestRequest(method: .post, url: (globalData.server?.baseURI ?? "") + "/Sessions/Playing/Progress")
        request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
        request.contentType = "application/json"
        request.acceptType = "application/json"
        request.messageBody = progressBody.data(using: .ascii);
        request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
            switch result {
            case .success(let resp):
                print(resp.body)
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
            progressBody  = "{\"VolumeLevel\":100,\"IsMuted\":false,\"IsPaused\":true,\"RepeatMode\":\"RepeatNone\",\"ShuffleMode\":\"Sorted\",\"MaxStreamingBitrate\":120000000,\"PositionTicks\":\(Int(vlcplayer.position * Float(item.RuntimeTicks))),\"PlaybackStartTimeTicks\":\(startTime),\"AudioStreamIndex\":\(selectedAudioTrack),\"BufferedRanges\":[],\"PlayMethod\":\"DirectStream\",\"PlaySessionId\":\"\(playSessionId)\",\"PlaylistItemId\":\"playlistItem0\",\"MediaSourceId\":\"\(item.Id)\",\"CanSeek\":true,\"ItemId\":\"\(item.Id)\",\"NowPlayingQueue\":[{\"Id\":\"\(item.Id)\",\"PlaylistItemId\":\"playlistItem0\"}]}";
        } else {
            progressBody  = "{\"VolumeLevel\":100,\"IsMuted\":false,\"IsPaused\":true,\"RepeatMode\":\"RepeatNone\",\"ShuffleMode\":\"Sorted\",\"MaxStreamingBitrate\":120000000,\"PositionTicks\":\(Int(vlcplayer.position * Float(item.RuntimeTicks))),\"PlaybackStartTimeTicks\":\(startTime),\"AudioStreamIndex\":\(selectedAudioTrack),\"BufferedRanges\":[{\"start\":0,\"end\":100000}],\"PlayMethod\":\"Transcode\",\"PlaySessionId\":\"\(playSessionId)\",\"PlaylistItemId\":\"playlistItem0\",\"MediaSourceId\":\"\(item.Id)\",\"CanSeek\":true,\"ItemId\":\"\(item.Id)\",\"NowPlayingQueue\":[{\"Id\":\"\(item.Id)\",\"PlaylistItemId\":\"playlistItem0\"}]}";
        }
        
        let request = RestRequest(method: .post, url: (globalData.server?.baseURI ?? "") + "/Sessions/Playing/Stopped")
        request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
        request.contentType = "application/json"
        request.acceptType = "application/json"
        request.messageBody = progressBody.data(using: .ascii);
        request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
            switch result {
            case .success(let resp):
                print(resp.body)
                self.playing.wrappedValue = false;
                break
            case .failure(let error):
                debugPrint(error)
                break
            }
        }
    }
    
    func sendPlayReport() {
        var progressBody: String = "";
        _startTime.wrappedValue = Int(Date().timeIntervalSince1970) * 10000000
        if(pbitem.videoType == VideoType.hls) {
            progressBody  = "{\"VolumeLevel\":100,\"IsMuted\":false,\"IsPaused\":true,\"RepeatMode\":\"RepeatNone\",\"ShuffleMode\":\"Sorted\",\"MaxStreamingBitrate\":120000000,\"PositionTicks\":\(Int(item.Progress)),\"PlaybackStartTimeTicks\":\(startTime),\"AudioStreamIndex\":\(selectedAudioTrack),\"BufferedRanges\":[{\"start\":0,\"end\":100000}],\"PlayMethod\":\"Transcode\",\"PlaySessionId\":\"\(playSessionId)\",\"PlaylistItemId\":\"playlistItem0\",\"MediaSourceId\":\"\(item.Id)\",\"CanSeek\":true,\"ItemId\":\"\(item.Id)\",\"NowPlayingQueue\":[{\"Id\":\"\(item.Id)\",\"PlaylistItemId\":\"playlistItem0\"}]}";
        } else {
            progressBody  = "{\"VolumeLevel\":100,\"IsMuted\":false,\"IsPaused\":false,\"RepeatMode\":\"RepeatNone\",\"ShuffleMode\":\"Sorted\",\"MaxStreamingBitrate\":120000000,\"PositionTicks\":\(Int(item.Progress)),\"PlaybackStartTimeTicks\":\(startTime),\"AudioStreamIndex\":\(selectedAudioTrack),\"BufferedRanges\":[],\"PlayMethod\":\"DirectStream\",\"PlaySessionId\":\"\(playSessionId)\",\"PlaylistItemId\":\"playlistItem0\",\"MediaSourceId\":\"\(item.Id)\",\"CanSeek\":true,\"ItemId\":\"\(item.Id)\",\"NowPlayingQueue\":[{\"Id\":\"\(item.Id)\",\"PlaylistItemId\":\"playlistItem0\"}]}";
        }
        print(progressBody)
        
        let request = RestRequest(method: .post, url: (globalData.server?.baseURI ?? "") + "/Sessions/Playing")
        request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
        request.contentType = "application/json"
        request.acceptType = "application/json"
        request.messageBody = progressBody.data(using: .ascii);
        request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
            switch result {
            case .success(let resp):
                print(resp.body)
                break
            case .failure(let error):
                debugPrint(error)
                break
            }
        }
    }
    
    func startStream() {
        
        let builder = DeviceProfileBuilder()
        let DeviceProfile = builder.buildProfile()
        
        let jsonEncoder = JSONEncoder()
        let jsonData = try! jsonEncoder.encode(DeviceProfile)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        print(jsonString)
        
        _streamLoading.wrappedValue = true;
        let url = (globalData.server?.baseURI ?? "") + "/Items/\(item.Id)/PlaybackInfo?UserId=\(globalData.user?.user_id ?? "")&StartTimeTicks=\(Int(item.Progress))&IsPlayback=true&AutoOpenLiveStream=true&MaxStreamingBitrate=\(DeviceProfile.DeviceProfile.MaxStreamingBitrate)";
        let request = RestRequest(method: .post, url: url)
        
        request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
        request.contentType = "application/json"
        request.acceptType = "application/json"
        request.messageBody = jsonData
         
        request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
            switch result {
            case .success(let response):
                let body = response.body
                do {
                    let json = try JSON(data: body)
                    _playSessionId.wrappedValue = json["PlaySessionId"].string ?? "";
                    if(json["MediaSources"][0]["TranscodingUrl"].string != nil) {
                        print("Transcoding!")
                        let streamURL: URL = URL(string: "\(globalData.server?.baseURI ?? "")\((json["MediaSources"][0]["TranscodingUrl"].string ?? ""))")!
                        let item = PlaybackItem(videoType: VideoType.hls, videoUrl: streamURL, subtitles: [])
                        let disableSubtitleTrack = Subtitle(name: "Disabled", id: -1, url: URL(string: "https://example.com")!, delivery: "Embed")
                        _subtitles.wrappedValue.append(disableSubtitleTrack);
                        for (_,stream):(String, JSON) in json["MediaSources"][0]["MediaStreams"] {
                            if(stream["Type"].string == "Subtitle") {
                                let deliveryUrl = URL(string: "\(globalData.server?.baseURI ?? "")\(stream["DeliveryUrl"].string ?? "")")!
                                let subtitle = Subtitle(name: stream["DisplayTitle"].string ?? "", id: Int32(stream["Index"].int ?? 0), url: deliveryUrl, delivery: stream["DeliveryMethod"].string ?? "")
                                _subtitles.wrappedValue.append(subtitle);
                            }
                            
                            if(stream["Type"].string == "Audio") {
                                let deliveryUrl = URL(string: "https://example.com")!
                                let subtitle = Subtitle(name: stream["DisplayTitle"].string ?? "", id: Int32(stream["Index"].int ?? 0), url: deliveryUrl, delivery: stream["IsExternal"].boolValue ? "External" : "Embed")
                                if(stream["IsDefault"].boolValue) {
                                    _selectedAudioTrack.wrappedValue = Int32(stream["Index"].int ?? 0);
                                }
                                _audioTracks.wrappedValue.append(subtitle);
                            }
                        }
                        
                        if(_selectedAudioTrack.wrappedValue == -1) {
                            _selectedAudioTrack.wrappedValue = _audioTracks.wrappedValue[0].id;
                        }
                        
                        pbitem = item;
                        pbitem.subtitles = subtitles;
                        sendPlayReport();
                        _isPlaying.wrappedValue = true;
                    } else {
                        print("Direct playing!");
                        let streamURL: URL = URL(string: "\(globalData.server?.baseURI ?? "")/Videos/\(item.Id)/stream?Static=true&mediaSourceId=\(item.Id)&deviceId=\(globalData.user?.device_uuid ?? "")&api_key=\(globalData.authToken)&Tag=\(json["MediaSources"][0]["ETag"])")!;
                        let item = PlaybackItem(videoType: VideoType.direct, videoUrl: streamURL, subtitles: [])
                        let disableSubtitleTrack = Subtitle(name: "Disabled", id: -1, url: URL(string: "https://example.com")!, delivery: "Embed")
                        _subtitles.wrappedValue.append(disableSubtitleTrack);
                        for (_,stream):(String, JSON) in json["MediaSources"][0]["MediaStreams"] {
                            if(stream["Type"].string == "Subtitle") {
                                let deliveryUrl = URL(string: "\(globalData.server?.baseURI ?? "")\(stream["DeliveryUrl"].string ?? "")")!
                                let subtitle = Subtitle(name: stream["DisplayTitle"].string ?? "", id: Int32(stream["Index"].int ?? 0), url: deliveryUrl, delivery: stream["DeliveryMethod"].string ?? "")
                                _subtitles.wrappedValue.append(subtitle);
                            }
                            
                            if(stream["Type"].string == "Audio") {
                                let deliveryUrl = URL(string: "https://example.com")!
                                let subtitle = Subtitle(name: stream["DisplayTitle"].string ?? "", id: Int32(stream["Index"].int ?? 0), url: deliveryUrl, delivery: stream["IsExternal"].boolValue ? "External" : "Embed")
                                if(stream["IsDefault"].boolValue) {
                                    _selectedAudioTrack.wrappedValue = Int32(stream["Index"].int ?? 0);
                                }
                                _audioTracks.wrappedValue.append(subtitle);
                            }
                        }
                        
                        if(_selectedAudioTrack.wrappedValue == -1) {
                            _selectedAudioTrack.wrappedValue = _audioTracks.wrappedValue[0].id;
                        }
                        
                        pbitem = item;
                        pbitem.subtitles = subtitles;
                        sendPlayReport();
                        _isPlaying.wrappedValue = true;
                    }
                    
                    DispatchQueue.global(qos: .utility).async { [self] in
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
            usleep(100000)
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
                                sendStopReport()
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
                                sendProgressReport(eventName: "pause")
                            } else {
                                vlcplayer.play()
                                playPauseButtonSystemName = "pause"
                                sendProgressReport(eventName: "unpause")
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
                                sendProgressReport(eventName: "pause")
                                DispatchQueue.global(qos: .utility).async { [self] in
                                    self.processScrubbingState()
                                }
                            } else {
                                //Scrub is value from 0..1 - find position in video and add / or remove.
                                let secondsScrubbedTo = round(_scrub.wrappedValue * videoDuration);
                                let offset = secondsScrubbedTo - videoPosition;
                                sendProgressReport(eventName: "unpause")
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
                }
                .padding(EdgeInsets(top: 0, leading: UIDevice.current.hasNotch ? -30 : 0, bottom: 0, trailing: UIDevice.current.hasNotch ? -30 : 0))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.black).opacity(0.4))
                .isHidden(inactivity)
            }.padding(EdgeInsets(top: 0, leading: UIDevice.current.hasNotch ? 34 : 0, bottom: 0, trailing: UIDevice.current.hasNotch ? 34 : 0))
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .onAppear(perform: startStream)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .prefersHomeIndicatorAutoHidden(true)
        .preferredColorScheme(.dark)
        .introspectTabBarController { (UITabBarController) in
            UITabBarController.tabBar.isHidden = true
        }
        .statusBar(hidden: true)
        .edgesIgnoringSafeArea(.all)
        .onTapGesture(perform: resetTimer)
        .fullScreenCover(isPresented: self.$captionConfiguration) {
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
                        Picker("Audio Track", selection: $selectedAudioTrack) {
                            ForEach(audioTracks, id: \.id) { caption in
                                Text(caption.name).tag(caption.id)
                            }
                        }.onChange(of: selectedAudioTrack) { track in
                            vlcplayer.currentAudioTrackIndex = track;
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
