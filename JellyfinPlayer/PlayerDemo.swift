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

extension UIDevice
{
    //Original Author: HAS
    // https://stackoverflow.com/questions/26028918/how-to-determine-the-current-iphone-device-model
    // Modified by Sam Trent

    /**********************************************
    *  getCPUName():
    *     Returns a hardcoded value of the current
    * devices CPU name.
    ***********************************************/
    public func getCPUName() -> Float
    {
        let processorNames = Array(CPUinfo().keys)
        return processorNames[0]
    }

    /**********************************************
    *  getCPUSpeed():
    *     Returns a hardcoded value of the current
    * devices CPU speed as specified by Apple.
    ***********************************************/
    public func getCPUSpeed() -> String
    {
        let processorSpeed = Array(CPUinfo().values)
        return processorSpeed[0]
    }

    /**********************************************
    *  CPUinfo:
    *     Returns a dictionary of the name of the
    *  current devices processor and speed.
    ***********************************************/
    private func CPUinfo() -> Dictionary<Float, String> {

        #if targetEnvironment(simulator)
        let identifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"]!
        #else

        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        #endif

        switch identifier {
            case "iPod5,1":                                 return [5:"800 MHz"] // underclocked
            case "iPod7,1":                                 return [8:"1.4 GHz"]
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return [4:"800 MHz"] // underclocked
            case "iPhone4,1":                               return [5:"800 MHz"] // underclocked
            case "iPhone5,1", "iPhone5,2":                  return [6:"1.3 GHz"]
            case "iPhone5,3", "iPhone5,4":                  return [6:"1.3 GHz"]
            case "iPhone6,1", "iPhone6,2":                  return [7:"1.3 GHz"]
            case "iPhone7,2":                               return [8:"1.4 GHz"]
            case "iPhone7,1":                               return [8:"1.4 GHz"]
            case "iPhone8,1":                               return [9:"1.85 GHz"]
            case "iPhone8,2":                               return [9:"1.85 GHz"]
        case "iPhone9,1", "iPhone9,3":                  return [10:"2.34 GHz"]
            case "iPhone9,2", "iPhone9,4":                  return [10:"2.34 GHz"]
            case "iPhone8,4":                               return [9:"1.85 GHz"]
            case "iPhone10,1", "iPhone10,4":                return [11:"2.39 GHz"]
            case "iPhone10,2", "iPhone10,5":                return [11:"2.39 GHz"]
            case "iPhone10,3", "iPhone10,6":                return [11:"2.39 GHz"]
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return [5:"1.0 GHz"]
        case "iPad3,1", "iPad3,2", "iPad3,3":           return [5.5:"1.0 GHz"]
        case "iPad3,4", "iPad3,5", "iPad3,6":           return [6.5:"1.4 GHz"]
            case "iPad4,1", "iPad4,2", "iPad4,3":           return [7:"1.4 GHz"]
        case "iPad5,3", "iPad5,4":                      return [8.5:"1.5 GHz"]
            case "iPad6,11", "iPad6,12":                    return [9:"1.85 GHz"]
            case "iPad2,5", "iPad2,6", "iPad2,7":           return [5:"1.0 GHz"]
            case "iPad4,4", "iPad4,5", "iPad4,6":           return [7:"1.3 GHz"]
            case "iPad4,7", "iPad4,8", "iPad4,9":           return [7:"1.3 GHz"]
            case "iPad5,1", "iPad5,2":                      return [8:"1.5 GHz"]
        case "iPad6,3", "iPad6,4":                      return [9.5:"2.16 GHz"] // underclocked
        case "iPad6,7", "iPad6,8":                      return [9.5:"2.24 GHz"]
        case "iPad7,1", "iPad7,2":                      return [10.5:"2.34 GHz"]
        case "iPad7,3", "iPad7,4":                      return [10.5:"2.34 GHz"]
            case "AppleTV5,3":                              return [8:"1.4 GHz"]
        case "AppleTV6,2":                              return [10.5:"2.34 GHz"]
            case "AudioAccessory1,1":                       return [8:"1.4 GHz"] // clock speed is a guess
            default:                                        return [99:"N/A"]
        }
    }
}

struct PlayerDemo: View {
    @EnvironmentObject var globalData: GlobalData
    var item: DetailItem;
    @State private var pbitem: PlaybackItem = PlaybackItem(videoType: VideoType.direct, videoUrl: URL(string: "https://example.com")!, subtitles: []);
    @State private var streamLoading = false;
    @State private var vlcplayer: VLCMediaPlayer = VLCMediaPlayer(options: ["--sub-margin=-50"]);
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
        
        let cpuModel = UIDevice.current.getCPUName();
        
        var directStreamVideoProfiles: [String] = ["h264"];
        var transcodedStreamVideoProfiles: [String] = ["h264"];
        var directStreamAudioProfiles: [String] = ["aac","mp3","vorbis"];
        var transcodedStreamAudioProfiles: [String] = ["aac","mp3","vorbis"];
        
        //HEVC support started 9 (9) - also adds Dolby Digital & FLAC
        if(cpuModel >= 9) {
            directStreamVideoProfiles.append("hevc");
            transcodedStreamVideoProfiles.append("hevc");
            
            directStreamAudioProfiles.append("ac3");
            directStreamAudioProfiles.append("eac3");
            directStreamAudioProfiles.append("flac");
            
            transcodedStreamAudioProfiles.append("ac3");
            transcodedStreamAudioProfiles.append("eac3");
            transcodedStreamAudioProfiles.append("flac");
        }
        
        //Dolby Vision support started 11 Bionic (11)
        if(cpuModel >= 11) {
            directStreamVideoProfiles.append("dvav");
            transcodedStreamVideoProfiles.append("dvav");
            directStreamVideoProfiles.append("dva1");
            transcodedStreamVideoProfiles.append("dva1");
            directStreamVideoProfiles.append("dvh1");
            transcodedStreamVideoProfiles.append("dvh1");
            directStreamVideoProfiles.append("dvhe");
            transcodedStreamVideoProfiles.append("dvhe");
        }
        
        //Dolby Atmos support started 12 Bionic (12)
        if(cpuModel >= 12) {
            directStreamAudioProfiles.append("dts");
            directStreamAudioProfiles.append("truehd");
            directStreamAudioProfiles.append("dca");
            
            transcodedStreamAudioProfiles.append("dts");
            transcodedStreamAudioProfiles.append("truehd");
            transcodedStreamAudioProfiles.append("dca");
        }
        
        _streamLoading.wrappedValue = true;
        let request = RestRequest(method: .post, url: (globalData.server?.baseURI ?? "") + "/Items/\(item.Id)/PlaybackInfo?UserId=\(globalData.user?.user_id ?? "")&StartTimeTicks=\(Int(item.Progress))&IsPlayback=true&AutoOpenLiveStream=true&MaxStreamingBitrate=70000000")
        request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
        request.contentType = "application/json"
        request.acceptType = "application/json"
        request.messageBody = "{\"DeviceProfile\":{\"MaxStreamingBitrate\":70000000,\"MaxStaticBitrate\":140000000,\"MusicStreamingTranscodingBitrate\":384000,\"DirectPlayProfiles\":[{\"Container\":\"mp4,m4v,mkv,mov\",\"Type\":\"Video\",\"VideoCodec\":\"\(directStreamVideoProfiles.joined(separator: ","))\",\"AudioCodec\":\"\(directStreamAudioProfiles.joined(separator: ","))\"},{\"Container\":\"mp3\",\"Type\":\"Audio\"},{\"Container\":\"aac\",\"Type\":\"Audio\"},{\"Container\":\"m4a\",\"AudioCodec\":\"aac\",\"Type\":\"Audio\"},{\"Container\":\"m4b\",\"AudioCodec\":\"aac\",\"Type\":\"Audio\"},{\"Container\":\"flac\",\"Type\":\"Audio\"},{\"Container\":\"alac\",\"Type\":\"Audio\"},{\"Container\":\"m4a\",\"AudioCodec\":\"alac\",\"Type\":\"Audio\"},{\"Container\":\"m4b\",\"AudioCodec\":\"alac\",\"Type\":\"Audio\"},{\"Container\":\"webma\",\"Type\":\"Audio\"},{\"Container\":\"webm\",\"AudioCodec\":\"webma\",\"Type\":\"Audio\"},{\"Container\":\"wav\",\"Type\":\"Audio\"}],\"TranscodingProfiles\":[{\"Container\":\"aac\",\"Type\":\"Audio\",\"AudioCodec\":\"aac\",\"Context\":\"Streaming\",\"Protocol\":\"hls\",\"MaxAudioChannels\":\"6\",\"MinSegments\":\"2\",\"BreakOnNonKeyFrames\":true},{\"Container\":\"aac\",\"Type\":\"Audio\",\"AudioCodec\":\"aac\",\"Context\":\"Streaming\",\"Protocol\":\"http\",\"MaxAudioChannels\":\"6\"},{\"Container\":\"mp3\",\"Type\":\"Audio\",\"AudioCodec\":\"mp3\",\"Context\":\"Streaming\",\"Protocol\":\"http\",\"MaxAudioChannels\":\"6\"},{\"Container\":\"wav\",\"Type\":\"Audio\",\"AudioCodec\":\"wav\",\"Context\":\"Streaming\",\"Protocol\":\"http\",\"MaxAudioChannels\":\"6\"},{\"Container\":\"mp3\",\"Type\":\"Audio\",\"AudioCodec\":\"mp3\",\"Context\":\"Static\",\"Protocol\":\"http\",\"MaxAudioChannels\":\"6\"},{\"Container\":\"aac\",\"Type\":\"Audio\",\"AudioCodec\":\"aac\",\"Context\":\"Static\",\"Protocol\":\"http\",\"MaxAudioChannels\":\"6\"},{\"Container\":\"wav\",\"Type\":\"Audio\",\"AudioCodec\":\"wav\",\"Context\":\"Static\",\"Protocol\":\"http\",\"MaxAudioChannels\":\"6\"},{\"Container\":\"ts\",\"Type\":\"Video\",\"AudioCodec\":\"\(transcodedStreamAudioProfiles.joined(separator: ","))\",\"VideoCodec\":\"\(transcodedStreamVideoProfiles.joined(separator: ","))\",\"Context\":\"Streaming\",\"Protocol\":\"hls\",\"MaxAudioChannels\":\"6\",\"MinSegments\":\"2\",\"BreakOnNonKeyFrames\":true},{\"Container\":\"mp4\",\"Type\":\"Video\",\"AudioCodec\":\"\(transcodedStreamAudioProfiles.joined(separator: ","))\",\"VideoCodec\":\"\(transcodedStreamVideoProfiles.joined(separator: ","))\",\"Context\":\"Static\",\"Protocol\":\"http\"}],\"ContainerProfiles\":[],\"CodecProfiles\":[{\"Type\":\"Video\",\"Codec\":\"h264\",\"Conditions\":[{\"Condition\":\"NotEquals\",\"Property\":\"IsAnamorphic\",\"Value\":\"true\",\"IsRequired\":false},{\"Condition\":\"EqualsAny\",\"Property\":\"VideoProfile\",\"Value\":\"high|main|baseline|constrained baseline\",\"IsRequired\":false},{\"Condition\":\"LessThanEqual\",\"Property\":\"VideoLevel\",\"Value\":\"80\",\"IsRequired\":false},{\"Condition\":\"NotEquals\",\"Property\":\"IsInterlaced\",\"Value\":\"true\",\"IsRequired\":false}]},{\"Type\":\"Video\",\"Codec\":\"hevc\",\"Conditions\":[{\"Condition\":\"NotEquals\",\"Property\":\"IsAnamorphic\",\"Value\":\"true\",\"IsRequired\":false},{\"Condition\":\"EqualsAny\",\"Property\":\"VideoProfile\",\"Value\":\"main|main 10\",\"IsRequired\":false},{\"Condition\":\"LessThanEqual\",\"Property\":\"VideoLevel\",\"Value\":\"160\",\"IsRequired\":false},{\"Condition\":\"NotEquals\",\"Property\":\"IsInterlaced\",\"Value\":\"true\",\"IsRequired\":false}]}],\"SubtitleProfiles\":[{\"Format\":\"vtt\",\"Method\":\"External\"},{\"Format\":\"ass\",\"Method\":\"External\"},{\"Format\":\"ssa\",\"Method\":\"External\"},{\"Format\":\"pgssub\",\"Method\":\"Embed\"},{\"Format\":\"pgs\",\"Method\":\"Embed\"},{\"Format\":\"sub\",\"Method\":\"Embed\"}],\"ResponseProfiles\":[{\"Type\":\"Video\",\"Container\":\"m4v\",\"MimeType\":\"video/mp4\"}]}}".data(using: .ascii);
         
        request.responseData() { (result: Result<RestResponse<Data>, RestError>) in
            switch result {
            case .success(let response):
                let body = response.body
                do {
                    let json = try JSON(data: body)
                    _playSessionId.wrappedValue = json["PlaySessionId"].string ?? "";
                    if(json["MediaSources"][0]["TranscodingUrl"].string != nil) {
                        let streamURL: URL = URL(string: "\(globalData.server?.baseURI ?? "")\((json["MediaSources"][0]["TranscodingUrl"].string ?? "").replacingOccurrences(of: "master.m3u8", with: "main.m3u8"))")!
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
                        }
                        pbitem = item;
                        pbitem.subtitles = subtitles;
                        _isPlaying.wrappedValue = true;
                    }
                    
                    DispatchQueue.global(qos: .userInteractive).async { [self] in
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
            usleep(50000)
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
                }).background(Color(UIColor.green).opacity(0.4))
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
                }
                .padding(EdgeInsets(top: 0, leading: UIDevice.current.hasNotch ? -30 : 0, bottom: 0, trailing: UIDevice.current.hasNotch ? -30 : 0))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.red).opacity(0.4))
                .isHidden(inactivity)
            }.padding(EdgeInsets(top: 0, leading: UIDevice.current.hasNotch ? 34 : 0, bottom: 0, trailing: UIDevice.current.hasNotch ? 34 : 0))
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .background(Color(UIColor.blue).opacity(0.4))
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
