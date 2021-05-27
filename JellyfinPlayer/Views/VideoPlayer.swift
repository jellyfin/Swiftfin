//
//  VideoPlayer.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/26/21.
//

import SwiftUI
import MobileVLCKit
import SwiftyJSON
import SwiftyRequest

enum VideoType {
    case hls;
    case direct;
}

struct Subtitle {
    var name: String;
    var id: Int32;
    var url: URL;
    var delivery: String;
    var codec: String;
}

struct AudioTrack {
    var name: String;
    var id: Int32;
}

class PlaybackItem: ObservableObject {
    @Published var videoType: VideoType = .hls;
    @Published var videoUrl: URL = URL(string: "https://example.com")!;
}

protocol PlayerViewControllerDelegate: AnyObject {
    func hideLoadingView(_ viewController: PlayerViewController)
    func showLoadingView(_ viewController: PlayerViewController)
    func exitPlayer(_ viewController: PlayerViewController)
}

class PlayerViewController: UIViewController, VLCMediaDelegate, VLCMediaPlayerDelegate {

    weak var delegate: PlayerViewControllerDelegate?
    
    var mediaPlayer = VLCMediaPlayer()
    var globalData = GlobalData()
    
    @IBOutlet weak var timeText: UILabel!
    @IBOutlet weak var videoContentView: UIView!
    @IBOutlet weak var videoControlsView: UIView!
    @IBOutlet weak var seekSlider: UISlider!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var jumpBackButton: UIButton!
    @IBOutlet weak var jumpForwardButton: UIButton!
    @IBOutlet weak var playerSettingsButton: UIButton!
    
    var shouldShowLoadingScreen: Bool = false;
    var ssTargetValueOffset: Int = 0;
    var ssStartValue: Int = 0;
    
    var paused: Bool = true;
    var lastTime: Float = 0.0;
    var startTime: Int = 0;
    var controlsAppearTime: Double = 0;
    
    var selectedAudioTrack: Int32 = -1;
    var selectedCaptionTrack: Int32 = -1;
    var playSessionId: String = "";
    var lastProgressReportTime: Double = 0;
    
    var subtitleTrackArray: [Subtitle] = [];
    var audioTrackArray: [AudioTrack] = [];
    
    var manifest: DetailItem = DetailItem();
    var playbackItem = PlaybackItem();

    @IBAction func seekSliderStart(_ sender: Any) {
        sendProgressReport(eventName: "pause")
        mediaPlayer.pause()
    }
    
    @IBAction func seekSliderValueChanged(_ sender: Any) {
        let videoDuration = Double(mediaPlayer.time.intValue + abs(mediaPlayer.remainingTime.intValue))/1000
        let secondsScrubbedTo = round(Double(seekSlider.value) * videoDuration);
        let scrubRemaining = videoDuration - secondsScrubbedTo;
        let remainingTime = scrubRemaining;
        let hours = floor(remainingTime / 3600);
        let minutes = (remainingTime.truncatingRemainder(dividingBy: 3600)) / 60;
        let seconds = (remainingTime.truncatingRemainder(dividingBy: 3600)).truncatingRemainder(dividingBy: 60);
        if(hours != 0) {
            timeText.text = "\(Int(hours)):\(String(Int(floor(minutes))).leftPad(toWidth: 2, withString: "0")):\(String(Int(floor(seconds))).leftPad(toWidth: 2, withString: "0"))";
        } else {
            timeText.text = "\(String(Int(floor(minutes))).leftPad(toWidth: 2, withString: "0")):\(String(Int(floor(seconds))).leftPad(toWidth: 2, withString: "0"))";
        }
    }
    
    @IBAction func seekSliderEnd(_ sender: Any) {
        print("ss end")
        let videoPosition = Double(mediaPlayer.time.intValue)
        let videoDuration = Double(mediaPlayer.time.intValue + abs(mediaPlayer.remainingTime.intValue))
        //Scrub is value from 0..1 - find position in video and add / or remove.
        let secondsScrubbedTo = round(Double(seekSlider.value) * videoDuration);
        let offset = secondsScrubbedTo - videoPosition;
        mediaPlayer.play()
        if(offset > 0) {
            mediaPlayer.jumpForward(Int32(offset)/1000);
        } else {
            mediaPlayer.jumpBackward(Int32(abs(offset))/1000);
        }
        sendProgressReport(eventName: "unpause")
    }
    
    @IBAction func exitButtonPressed(_ sender: Any) {
        sendStopReport()
        delegate?.exitPlayer(self)
    }
    
    @IBAction func controlViewTapped(_ sender: Any) {
        videoControlsView.isHidden = true
    }
    
    @IBAction func contentViewTapped(_ sender: Any) {
        videoControlsView.isHidden = false
        controlsAppearTime = CACurrentMediaTime()
    }
    
    @IBAction func jumpBackTapped(_ sender: Any) {
        if(paused == false) {
            mediaPlayer.jumpBackward(15)
        }
    }
    
    @IBAction func jumpForwardTapped(_ sender: Any) {
        if(paused == false) {
            mediaPlayer.jumpForward(15)
        }
    }
    
    
    
    @IBOutlet weak var mainActionButton: UIButton!
    @IBAction func mainActionButtonPressed(_ sender: Any) {
        print(mediaPlayer.state.rawValue)
        if(paused) {
            mediaPlayer.play()
            mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
            paused = false;
        } else {
            mediaPlayer.pause()
            mainActionButton.setImage(UIImage(systemName: "play"), for: .normal)
            paused = true;
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //View has loaded.
        //Show loading screen
        delegate?.showLoadingView(self)
        
        mediaPlayer.perform(Selector(("setTextRendererFontSize:")), with: 14)
        //mediaPlayer.wrappedValue.perform(Selector(("setTextRendererFont:")), with: "Copperplate")
        
        
        mediaPlayer.delegate = self
        mediaPlayer.drawable = videoContentView
        
        if(manifest.Type == "Episode") {
            titleLabel.text = "\(manifest.Name) -  S\(String(manifest.ParentIndexNumber ?? 0)):E\(String(manifest.IndexNumber ?? 0)) - \(manifest.SeriesName ?? "")"
        } else {
            titleLabel.text = manifest.Name
        }
        
        //Fetch max bitrate from UserDefaults depending on current connection mode
        let defaults = UserDefaults.standard
        let maxBitrate = globalData.isInNetwork ? defaults.integer(forKey: "InNetworkBandwidth") : defaults.integer(forKey: "OutOfNetworkBandwidth")
        
        //Build a device profile
        let builder = DeviceProfileBuilder()
        builder.setMaxBitrate(bitrate: maxBitrate)
        let profile = builder.buildProfile()
        
        let jsonEncoder = JSONEncoder()
        let jsonData = try! jsonEncoder.encode(profile)
        
        let url = (globalData.server?.baseURI ?? "") + "/Items/\(manifest.Id)/PlaybackInfo?UserId=\(globalData.user?.user_id ?? "")&StartTimeTicks=\(Int(manifest.Progress))&IsPlayback=true&AutoOpenLiveStream=true&MaxStreamingBitrate=\(profile.DeviceProfile.MaxStreamingBitrate)";

        let request = RestRequest(method: .post, url: url)
        
        request.headerParameters["X-Emby-Authorization"] = globalData.authHeader
        request.contentType = "application/json"
        request.acceptType = "application/json"
        request.messageBody = jsonData
         
        request.responseData() { [self] (result: Result<RestResponse<Data>, RestError>) in
            switch result {
            case .success(let response):
                let body = response.body
                do {
                    let json = try JSON(data: body)
                    playSessionId = json["PlaySessionId"].string ?? "";
                    if(json["MediaSources"][0]["TranscodingUrl"].string != nil) {
                        let streamURL: URL = URL(string: "\(globalData.server?.baseURI ?? "")\((json["MediaSources"][0]["TranscodingUrl"].string ?? ""))")!
                        let item = PlaybackItem()
                        item.videoType = .hls
                        item.videoUrl = streamURL
                        let disableSubtitleTrack = Subtitle(name: "Disabled", id: -1, url: URL(string: "https://example.com")!, delivery: "Embed", codec: "")
                        subtitleTrackArray.append(disableSubtitleTrack);
                        
                        for (_,stream):(String, JSON) in json["MediaSources"][0]["MediaStreams"] {
                            if(stream["Type"].string == "Subtitle") { //ignore ripped subtitles - we don't want to extract subtitles
                                let deliveryUrl = URL(string: "\(globalData.server?.baseURI ?? "")\(stream["DeliveryUrl"].string ?? "")")!
                                let subtitle = Subtitle(name: stream["DisplayTitle"].string ?? "", id: Int32(stream["Index"].int ?? 0), url: deliveryUrl, delivery: stream["DeliveryMethod"].string ?? "", codec: stream["Codec"].string ?? "")
                                subtitleTrackArray.append(subtitle);
                            }
                            
                            if(stream["Type"].string == "Audio") {
                                let subtitle = AudioTrack(name: stream["DisplayTitle"].string ?? "", id: Int32(stream["Index"].int ?? 0))
                                if(stream["IsDefault"].boolValue) {
                                    selectedAudioTrack = Int32(stream["Index"].int ?? 0);
                                }
                                audioTrackArray.append(subtitle);
                            }
                        }
                        
                        if(selectedAudioTrack == -1) {
                            if(audioTrackArray.count > 0) {
                                selectedAudioTrack = audioTrackArray[0].id;
                            }
                        }
                        
                        self.sendPlayReport()
                        playbackItem = item;
                    } else {
                        print("Direct playing!");
                        let streamURL: URL = URL(string: "\(globalData.server?.baseURI ?? "")/Videos/\(manifest.Id)/stream?Static=true&mediaSourceId=\(manifest.Id)&deviceId=\(globalData.user?.device_uuid ?? "")&api_key=\(globalData.authToken)&Tag=\(json["MediaSources"][0]["ETag"])")!;
                        let item = PlaybackItem()
                        item.videoUrl = streamURL
                        item.videoType = .direct
                        
                        let disableSubtitleTrack = Subtitle(name: "Disabled", id: -1, url: URL(string: "https://example.com")!, delivery: "Embed", codec: "")
                        subtitleTrackArray.append(disableSubtitleTrack);
                        for (_,stream):(String, JSON) in json["MediaSources"][0]["MediaStreams"] {
                            if(stream["Type"].string == "Subtitle") {
                                let deliveryUrl = URL(string: "\(globalData.server?.baseURI ?? "")\(stream["DeliveryUrl"].string ?? "")")!
                                let subtitle = Subtitle(name: stream["DisplayTitle"].string ?? "", id: Int32(stream["Index"].int ?? 0), url: deliveryUrl, delivery: stream["DeliveryMethod"].string ?? "", codec: stream["Codec"].string ?? "")
                                subtitleTrackArray.append(subtitle);
                            }
                            
                            if(stream["Type"].string == "Audio") {
                                let subtitle = AudioTrack(name: stream["DisplayTitle"].string ?? "", id: Int32(stream["Index"].int ?? 0))
                                if(stream["IsDefault"].boolValue) {
                                    selectedAudioTrack = Int32(stream["Index"].int ?? 0);
                                }
                                audioTrackArray.append(subtitle);
                            }
                        }
                        
                        if(selectedAudioTrack == -1) {
                            if(audioTrackArray.count > 0) {
                                selectedAudioTrack = audioTrackArray[0].id;
                            }
                        }
                        
                        sendPlayReport()
                        playbackItem = item;
                    }
                    
                    DispatchQueue.global(qos: .background).async {
                        mediaPlayer.media = VLCMedia(url: playbackItem.videoUrl)
                        mediaPlayer.play()
                        subtitleTrackArray.forEach() { sub in
                            if(sub.id != -1 && sub.delivery == "External" && sub.codec != "subrip") {
                                print("adding subs for id: \(sub.id) w/ url: \(sub.url)")
                                mediaPlayer.addPlaybackSlave(sub.url, type: .subtitle, enforce: false)
                            }
                        }
                        mediaPlayer.pause()
                        delegate?.showLoadingView(self)
                        sleep(3)
                        mediaPlayer.pause()
                        mediaPlayer.currentVideoSubTitleIndex = selectedCaptionTrack;
                        mediaPlayer.play()
                        mediaPlayer.jumpForward(Int32(manifest.Progress/10000000))
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true;
    }
    
    
    //MARK: VLCMediaPlayer Delegates
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
            let currentState: VLCMediaPlayerState = mediaPlayer.state
            switch currentState {
            case .stopped :
                break;
            case .ended :
                break;
            case .playing :
                print("Video is playing")
                sendProgressReport(eventName: "unpause")
                delegate?.hideLoadingView(self)
                paused = false;
                
            case .paused :
                print("Video is paused)")
                paused = true;
                
            case .opening :
                print("Video is opening)")
                
            case .buffering :
                print("Video is buffering)")
                sendProgressReport(eventName: "pause")
                delegate?.showLoadingView(self)
                mediaPlayer.pause()
                usleep(10000)
                mediaPlayer.play()
                
            case .error :
                print("Video has error)")
                sendStopReport()
            case .esAdded:
                mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
            @unknown default:
                break
            }
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        let time = mediaPlayer.position;
        if(time != lastTime) {
            paused = false;
            seekSlider.setValue(mediaPlayer.position, animated: true)
            delegate?.hideLoadingView(self)
            
            let remainingTime = abs(mediaPlayer.remainingTime.intValue)/1000;
            let hours = remainingTime / 3600;
            let minutes = (remainingTime % 3600) / 60;
            let seconds = (remainingTime % 3600) % 60;
            var timeTextStr = "";
            if(hours != 0) {
                timeTextStr = "\(Int(hours)):\(String(Int((minutes))).leftPad(toWidth: 2, withString: "0")):\(String(Int((seconds))).leftPad(toWidth: 2, withString: "0"))";
            } else {
                timeTextStr = "\(String(Int((minutes))).leftPad(toWidth: 2, withString: "0")):\(String(Int((seconds))).leftPad(toWidth: 2, withString: "0"))";
            }
            timeText.text = timeTextStr
            
            if(CACurrentMediaTime() - controlsAppearTime > 5) {
                videoControlsView.isHidden = true;
                controlsAppearTime = 10000000000000000000000;
            }
        } else {
            paused = true;
        }
        lastTime = time;
        
        if(CACurrentMediaTime() - lastProgressReportTime > 5) {
            sendProgressReport(eventName: "timeupdate")
            lastProgressReportTime = CACurrentMediaTime()
        }
    }
    
    //MARK: Jellyfin Playstate updates
    func sendProgressReport(eventName: String) {
        var progressBody: String = "";
        progressBody  = "{\"VolumeLevel\":100,\"IsMuted\":false,\"IsPaused\":\(mediaPlayer.state == .paused ? "true" : "false"),\"RepeatMode\":\"RepeatNone\",\"ShuffleMode\":\"Sorted\",\"MaxStreamingBitrate\":120000000,\"PositionTicks\":\(Int(mediaPlayer.position * Float(manifest.RuntimeTicks))),\"PlaybackStartTimeTicks\":\(startTime),\"AudioStreamIndex\":\(selectedAudioTrack),\"BufferedRanges\":[{\"start\":0,\"end\":569735888.888889}],\"PlayMethod\":\"\(playbackItem.videoType == .hls ? "Transcode" : "DirectStream")\",\"PlaySessionId\":\"\(playSessionId)\",\"PlaylistItemId\":\"playlistItem0\",\"MediaSourceId\":\"\(manifest.Id)\",\"CanSeek\":true,\"ItemId\":\"\(manifest.Id)\",\"EventName\":\"\(eventName)\"}";
        
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
    
    func sendStopReport() {
        var progressBody: String = "";
        
        progressBody  = "{\"VolumeLevel\":100,\"IsMuted\":false,\"IsPaused\":true,\"RepeatMode\":\"RepeatNone\",\"ShuffleMode\":\"Sorted\",\"MaxStreamingBitrate\":120000000,\"PositionTicks\":\(Int(mediaPlayer.position * Float(manifest.RuntimeTicks))),\"PlaybackStartTimeTicks\":\(startTime),\"AudioStreamIndex\":\(selectedAudioTrack),\"BufferedRanges\":[{\"start\":0,\"end\":100000}],\"PlayMethod\":\"\(playbackItem.videoType == .hls ? "Transcode" : "DirectStream")\",\"PlaySessionId\":\"\(playSessionId)\",\"PlaylistItemId\":\"playlistItem0\",\"MediaSourceId\":\"\(manifest.Id)\",\"CanSeek\":true,\"ItemId\":\"\(manifest.Id)\",\"NowPlayingQueue\":[{\"Id\":\"\(manifest.Id)\",\"PlaylistItemId\":\"playlistItem0\"}]}";
        
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
        startTime = Int(Date().timeIntervalSince1970) * 10000000
        
        progressBody  = "{\"VolumeLevel\":100,\"IsMuted\":false,\"IsPaused\":false,\"RepeatMode\":\"RepeatNone\",\"ShuffleMode\":\"Sorted\",\"MaxStreamingBitrate\":120000000,\"PositionTicks\":\(Int(manifest.Progress)),\"PlaybackStartTimeTicks\":\(startTime),\"AudioStreamIndex\":\(selectedAudioTrack),\"BufferedRanges\":[],\"PlayMethod\":\"\(playbackItem.videoType == .hls ? "Transcode" : "DirectStream")\",\"PlaySessionId\":\"\(playSessionId)\",\"PlaylistItemId\":\"playlistItem0\",\"MediaSourceId\":\"\(manifest.Id)\",\"CanSeek\":true,\"ItemId\":\"\(manifest.Id)\",\"NowPlayingQueue\":[{\"Id\":\"\(manifest.Id)\",\"PlaylistItemId\":\"playlistItem0\"}]}";
        
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

struct VLCPlayerWithControls: UIViewControllerRepresentable {
    var item: DetailItem
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var globalData: GlobalData;
    
    var loadBinding: Binding<Bool>
    var pBinding: Binding<Bool>

    class Coordinator: NSObject, PlayerViewControllerDelegate {
        let loadBinding: Binding<Bool>
        let pBinding: Binding<Bool>
        
        init(loadBinding: Binding<Bool>, pBinding: Binding<Bool>) {
            self.loadBinding = loadBinding
            self.pBinding = pBinding
        }
        
        func hideLoadingView(_ viewController: PlayerViewController) {
            self.loadBinding.wrappedValue = false;
        }
        
        func showLoadingView(_ viewController: PlayerViewController) {
            self.loadBinding.wrappedValue = true;
        }
        
        func exitPlayer(_ viewController: PlayerViewController) {
            self.pBinding.wrappedValue = false;
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(loadBinding: self.loadBinding, pBinding: self.pBinding)
    }

    
    typealias UIViewControllerType = PlayerViewController
    func makeUIViewController(context: UIViewControllerRepresentableContext<VLCPlayerWithControls>) -> VLCPlayerWithControls.UIViewControllerType {
        let storyboard = UIStoryboard(name: "VideoPlayer", bundle: nil)
        let customViewController = storyboard.instantiateViewController(withIdentifier: "VideoPlayer") as! PlayerViewController
        customViewController.manifest = item;
        customViewController.delegate = context.coordinator;
        customViewController.globalData = globalData;
        return customViewController
    }

    func updateUIViewController(_ uiViewController: VLCPlayerWithControls.UIViewControllerType, context: UIViewControllerRepresentableContext<VLCPlayerWithControls>) {
    }
}
