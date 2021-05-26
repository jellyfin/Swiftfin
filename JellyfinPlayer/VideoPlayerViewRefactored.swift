//
//  VideoPlayerViewRefactored.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/26/21.
//

import SwiftUI
import MobileVLCKit
import Introspect
import SwiftyJSON
import SwiftyRequest

struct VideoPlayerViewRefactored: View {
    @EnvironmentObject private var globalData: GlobalData;
    
    @State private var shouldShowLoadingView: Bool = true;
    @State private var itemPlayback: ItemPlayback;
    
    @State private var VLCPlayerObj = VLCMediaPlayer()
    
    @State private var scrub: Double = 0; // storage value for scrubbing
    @State private var timeText: String = "-:--:--"; //shows time text on play overlay
    @State private var startTime: Int = 0; //ticks since 1970
    @State private var selectedAudioTrack: Int32 = 0;
    @State private var selectedCaptionTrack: Int32 = 0;
    @State private var playSessionId: String = "";
    @State private var shouldOverlayShow: Bool = false;
    
    @State private var subtitles: [Subtitle] = [];
    @State private var audioTracks: [Subtitle] = []; // can reuse the same struct
    
    @State private var VLCItem: PlaybackItem = PlaybackItem();
    
    init(itemPlayback: ItemPlayback) {
        self.itemPlayback = itemPlayback
    }
    
    var body: some View {
        LoadingView(isShowing: $shouldShowLoadingView) {
            VLCPlayer(url: $VLCItem, player: $VLCPlayerObj, startTime: Int(itemPlayback.itemToPlay.Progress)).onDisappear(perform: {
                VLCPlayerObj.stop()
            })
            .padding(EdgeInsets(top: 0, leading: UIDevice.current.hasNotch ? 30 : 0, bottom: 0, trailing: UIDevice.current.hasNotch ? 30 : 0))
        }
        .overlay(
            Group {
                if(shouldOverlayShow) {
                    VStack() {
                        HStack() {
                            HStack() {
                                Button() {
                                    sendStopReport()
                                    self.itemPlayback.shouldPlay = false;
                                } label: {
                                    HStack() {
                                        Image(systemName: "chevron.left").font(.system(size: 20)).foregroundColor(.white)
                                    }
                                }.frame(width: 20)
                                Spacer()
                                Text(itemPlayback.itemToPlay.Name).font(.headline).fontWeight(.semibold).foregroundColor(.white).offset(x:20)
                                Spacer()
                                Button() {
                                    VLCPlayerObj.pause()
                                } label: {
                                    HStack() {
                                        Image(systemName: "gear").font(.system(size: 20)).foregroundColor(.white)
                                    }
                                }.frame(width: 20).padding(.trailing,15)
                                Button() {
                                    VLCPlayerObj.pause()
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
                                VLCPlayerObj.jumpBackward(15)
                            } label: {
                                Image(systemName: "gobackward.15").font(.system(size: 40)).foregroundColor(.white)
                            }.padding(20)
                            Spacer()
                            Button() {
                                if(VLCPlayerObj.state != .paused) {
                                    VLCPlayerObj.pause()
                                    sendProgressReport(eventName: "pause")
                                } else {
                                    VLCPlayerObj.play()
                                    sendProgressReport(eventName: "unpause")
                                }
                            } label: {
                                Image(systemName: VLCPlayerObj.state == .paused ? "play" : "pause").font(.system(size: 55)).foregroundColor(.white)
                            }.padding(20).frame(width: 60, height: 60)
                            Spacer()
                            Button() {
                                VLCPlayerObj.jumpForward(15)
                            } label: {
                                Image(systemName: "goforward.15").font(.system(size: 40)).foregroundColor(.white)
                            }.padding(20)
                            Spacer()
                        }.padding(.leading, -20)
                        Spacer()
                        HStack() {
                            Slider(value: $scrub, onEditingChanged: { bool in
                                let videoPosition = Double(VLCPlayerObj.time.intValue)
                                let videoDuration = Double(VLCPlayerObj.time.intValue + abs(VLCPlayerObj.remainingTime.intValue))
                                if(bool == true) {
                                    VLCPlayerObj.pause()
                                    sendProgressReport(eventName: "pause")
                                } else {
                                    //Scrub is value from 0..1 - find position in video and add / or remove.
                                    let secondsScrubbedTo = round(_scrub.wrappedValue * videoDuration);
                                    let offset = secondsScrubbedTo - videoPosition;
                                    sendProgressReport(eventName: "unpause")
                                    VLCPlayerObj.play()
                                    if(offset > 0) {
                                        VLCPlayerObj.jumpForward(Int32(offset)/1000);
                                    } else {
                                        VLCPlayerObj.jumpBackward(Int32(abs(offset))/1000);
                                    }
                                }
                            })
                            .accentColor(Color(red: 172/255, green: 92/255, blue: 195/255))
                            Text(timeText).fontWeight(.semibold).frame(width: 80).foregroundColor(.white)
                        }.padding(EdgeInsets(top: -20, leading: 44, bottom: 42, trailing: 40))
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .background(Color(.black).opacity(0.4))
                }
            }
            , alignment: .topLeading)
        .introspectTabBarController { (UITabBarController) in
                    UITabBarController.tabBar.isHidden = true
        }
        .onTapGesture(perform: resetTimer)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .statusBar(hidden: true)
        .prefersHomeIndicatorAutoHidden(true)
        .preferredColorScheme(.dark)
        .edgesIgnoringSafeArea(.all)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .overrideViewPreference(.unspecified)
        .supportedOrientations(.landscape)
        .onAppear(perform: onAppear)
    }
    
    func onAppear() {
        shouldShowLoadingView = true;
        let builder = DeviceProfileBuilder()
        
        let defaults = UserDefaults.standard;
        if(globalData.isInNetwork) {
            builder.setMaxBitrate(bitrate: defaults.integer(forKey: "InNetworkBandwidth"))
        } else {
            builder.setMaxBitrate(bitrate: defaults.integer(forKey: "OutOfNetworkBandwidth"))
        }
        
        let DeviceProfile = builder.buildProfile()
        
        let jsonEncoder = JSONEncoder()
        let jsonData = try! jsonEncoder.encode(DeviceProfile)

        let url = (globalData.server?.baseURI ?? "") + "/Items/\(itemPlayback.itemToPlay.Id)/PlaybackInfo?UserId=\(globalData.user?.user_id ?? "")&StartTimeTicks=\(Int(itemPlayback.itemToPlay.Progress))&IsPlayback=true&AutoOpenLiveStream=true&MaxStreamingBitrate=\(DeviceProfile.DeviceProfile.MaxStreamingBitrate)";
        
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
                        let streamURL: URL = URL(string: "\(globalData.server?.baseURI ?? "")\((json["MediaSources"][0]["TranscodingUrl"].string ?? ""))")!
                        let item = PlaybackItem()
                        item.videoType = .hls
                        item.videoUrl = streamURL
                        let disableSubtitleTrack = Subtitle(name: "Disabled", id: -1, url: URL(string: "https://example.com")!, delivery: "Embed", codec: "")
                        _subtitles.wrappedValue.append(disableSubtitleTrack);
                        
                        for (_,stream):(String, JSON) in json["MediaSources"][0]["MediaStreams"] {
                            if(stream["Type"].string == "Subtitle") { //ignore ripped subtitles - we don't want to extract subtitles
                                let deliveryUrl = URL(string: "\(globalData.server?.baseURI ?? "")\(stream["DeliveryUrl"].string ?? "")")!
                                let subtitle = Subtitle(name: stream["DisplayTitle"].string ?? "", id: Int32(stream["Index"].int ?? 0), url: deliveryUrl, delivery: stream["DeliveryMethod"].string ?? "", codec: stream["Codec"].string ?? "")
                                _subtitles.wrappedValue.append(subtitle);
                            }
                            
                            if(stream["Type"].string == "Audio") {
                                let deliveryUrl = URL(string: "https://example.com")!
                                let subtitle = Subtitle(name: stream["DisplayTitle"].string ?? "", id: Int32(stream["Index"].int ?? 0), url: deliveryUrl, delivery: stream["IsExternal"].boolValue ? "External" : "Embed", codec: stream["Codec"].string ?? "")
                                if(stream["IsDefault"].boolValue) {
                                    _selectedAudioTrack.wrappedValue = Int32(stream["Index"].int ?? 0);
                                }
                                _audioTracks.wrappedValue.append(subtitle);
                            }
                        }
                        
                        if(_selectedAudioTrack.wrappedValue == -1) {
                            if(_audioTracks.wrappedValue.count > 0) {
                                _selectedAudioTrack.wrappedValue = _audioTracks.wrappedValue[0].id;
                            }
                        }
                        
                        self.sendPlayReport()
                        VLCItem = item;
                        VLCItem.subtitles = subtitles;
                    } else {
                        print("Direct playing!");
                        let streamURL: URL = URL(string: "\(globalData.server?.baseURI ?? "")/Videos/\(itemPlayback.itemToPlay.Id)/stream?Static=true&mediaSourceId=\(itemPlayback.itemToPlay.Id)&deviceId=\(globalData.user?.device_uuid ?? "")&api_key=\(globalData.authToken)&Tag=\(json["MediaSources"][0]["ETag"])")!;
                        let item = PlaybackItem()
                        item.videoUrl = streamURL
                        item.videoType = .direct
                        let disableSubtitleTrack = Subtitle(name: "Disabled", id: -1, url: URL(string: "https://example.com")!, delivery: "Embed", codec: "")
                        _subtitles.wrappedValue.append(disableSubtitleTrack);
                        for (_,stream):(String, JSON) in json["MediaSources"][0]["MediaStreams"] {
                            if(stream["Type"].string == "Subtitle") {
                                let deliveryUrl = URL(string: "\(globalData.server?.baseURI ?? "")\(stream["DeliveryUrl"].string ?? "")")!
                                let subtitle = Subtitle(name: stream["DisplayTitle"].string ?? "", id: Int32(stream["Index"].int ?? 0), url: deliveryUrl, delivery: stream["DeliveryMethod"].string ?? "", codec: stream["Codec"].string ?? "")
                                _subtitles.wrappedValue.append(subtitle);
                            }
                            
                            if(stream["Type"].string == "Audio") {
                                let deliveryUrl = URL(string: "https://example.com")!
                                let subtitle = Subtitle(name: stream["DisplayTitle"].string ?? "", id: Int32(stream["Index"].int ?? 0), url: deliveryUrl, delivery: stream["IsExternal"].boolValue ? "External" : "Embed", codec: stream["Codec"].string ?? "")
                                if(stream["IsDefault"].boolValue) {
                                    _selectedAudioTrack.wrappedValue = Int32(stream["Index"].int ?? 0);
                                }
                                _audioTracks.wrappedValue.append(subtitle);
                            }
                        }
                        
                        if(_selectedAudioTrack.wrappedValue == -1) {
                            _selectedAudioTrack.wrappedValue = _audioTracks.wrappedValue[0].id;
                        }
                        
                        sendPlayReport()
                        _VLCItem.wrappedValue = item;
                        _VLCItem.wrappedValue.subtitles = subtitles;
                    }
                    
                    shouldShowLoadingView = false;
                    
                    /*
                    DispatchQueue.global(qos: .utility).async { [self] in
                        self.keepUpWithPlayerState()
                    }
                    */
                } catch {
                    
                }
                break
            case .failure(let error):
                debugPrint(error)
                break
            }
        }
    }
    
    func sendProgressReport(eventName: String) {
        var progressBody: String = "";
        progressBody  = "{\"VolumeLevel\":100,\"IsMuted\":false,\"IsPaused\":\(VLCPlayerObj.state == .paused ? "true" : "false"),\"RepeatMode\":\"RepeatNone\",\"ShuffleMode\":\"Sorted\",\"MaxStreamingBitrate\":120000000,\"PositionTicks\":\(Int(VLCPlayerObj.position * Float(itemPlayback.itemToPlay.RuntimeTicks))),\"PlaybackStartTimeTicks\":\(startTime),\"AudioStreamIndex\":\(selectedAudioTrack),\"BufferedRanges\":[{\"start\":0,\"end\":569735888.888889}],\"PlayMethod\":\"\(VLCItem.videoType == .hls ? "Transcode" : "DirectStream")\",\"PlaySessionId\":\"\(playSessionId)\",\"PlaylistItemId\":\"playlistItem0\",\"MediaSourceId\":\"\(itemPlayback.itemToPlay.Id)\",\"CanSeek\":true,\"ItemId\":\"\(itemPlayback.itemToPlay.Id)\",\"EventName\":\"\(eventName)\"}";
        
        print("");
        print("Sending progress report")
        print(progressBody)
        
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
    
    func resetTimer() {
        print("rt running")
        if(_shouldOverlayShow.wrappedValue == true) {
            _shouldOverlayShow.wrappedValue = false
            return;
        }
        _shouldOverlayShow.wrappedValue = true;
    }
    
    func sendStopReport() {
        var progressBody: String = "";
        
        progressBody  = "{\"VolumeLevel\":100,\"IsMuted\":false,\"IsPaused\":true,\"RepeatMode\":\"RepeatNone\",\"ShuffleMode\":\"Sorted\",\"MaxStreamingBitrate\":120000000,\"PositionTicks\":\(Int(VLCPlayerObj.position * Float(itemPlayback.itemToPlay.RuntimeTicks))),\"PlaybackStartTimeTicks\":\(startTime),\"AudioStreamIndex\":\(selectedAudioTrack),\"BufferedRanges\":[{\"start\":0,\"end\":100000}],\"PlayMethod\":\"\(VLCItem.videoType == .hls ? "Transcode" : "DirectStream")\",\"PlaySessionId\":\"\(playSessionId)\",\"PlaylistItemId\":\"playlistItem0\",\"MediaSourceId\":\"\(itemPlayback.itemToPlay.Id)\",\"CanSeek\":true,\"ItemId\":\"\(itemPlayback.itemToPlay.Id)\",\"NowPlayingQueue\":[{\"Id\":\"\(itemPlayback.itemToPlay.Id)\",\"PlaylistItemId\":\"playlistItem0\"}]}";
        
        print("");
        print("Sending stop report")
        print(progressBody)
        
        let request = RestRequest(method: .post, url: (globalData.server?.baseURI ?? "") + "/Sessions/Playing/Stopped")
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
    
    func sendPlayReport() {
        var progressBody: String = "";
        _startTime.wrappedValue = Int(Date().timeIntervalSince1970) * 10000000
        
        progressBody  = "{\"VolumeLevel\":100,\"IsMuted\":false,\"IsPaused\":false,\"RepeatMode\":\"RepeatNone\",\"ShuffleMode\":\"Sorted\",\"MaxStreamingBitrate\":120000000,\"PositionTicks\":\(Int(itemPlayback.itemToPlay.Progress)),\"PlaybackStartTimeTicks\":\(startTime),\"AudioStreamIndex\":\(selectedAudioTrack),\"BufferedRanges\":[],\"PlayMethod\":\"\(VLCItem.videoType == .hls ? "Transcode" : "DirectStream")\",\"PlaySessionId\":\"\(playSessionId)\",\"PlaylistItemId\":\"playlistItem0\",\"MediaSourceId\":\"\(itemPlayback.itemToPlay.Id)\",\"CanSeek\":true,\"ItemId\":\"\(itemPlayback.itemToPlay.Id)\",\"NowPlayingQueue\":[{\"Id\":\"\(itemPlayback.itemToPlay.Id)\",\"PlaylistItemId\":\"playlistItem0\"}]}";
        
        print("");
        print("Sending play report")
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
}
