//
//  VLCPlayer.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/10/21.
//

//me realizing i shouldve just written the whole app in the mvvm system bc it makes so much more sense
//Please don't touch this ifle

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
    @Published var subtitles: [Subtitle] = [];
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

    var shouldShowLoadingScreen: Bool = false;
    var ssTargetValueOffset: Int = 0;
    var ssStartValue: Int = 0;
    
    var paused: Bool = true;
    var lastTime: Float = 0.0;
    var startTime: Int = 0;
    var selectedAudioTrack: Int32 = 0;
    var selectedCaptionTrack: Int32 = 0;
    var playSessionId: String = "";
    var lastProgressReportTime: Double = 0;
    
    var subtitleTrackArray: [Subtitle] = [];
    var audioTrackArray: [AudioTrack] = [];
    
    var manifest: DetailItem = DetailItem();
    var playbackItem = PlaybackItem();

    @IBAction func seekSliderStart(_ sender: Any) {
        print("ss start")
        mediaPlayer.pause()
    }
    @IBAction func seekSliderValueChanged(_ sender: Any) {
        print("ss mv " + String(seekSlider.value))
    }
    @IBAction func seekSliderEnd(_ sender: Any) {
        print("ss end")
        mediaPlayer.play()
    }
    
    @IBAction func exitButtonPressed(_ sender: Any) {
        sendStopReport()
        delegate?.exitPlayer(self)
    }
    
    @IBAction func controlViewTapped(_ sender: Any) {
        videoControlsView.isHidden = !videoControlsView.isHidden
    }
    
    @IBAction func contentViewTapped(_ sender: Any) {
        videoControlsView.isHidden = !videoControlsView.isHidden
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
        usleep(10000);
        delegate?.showLoadingView(self)
        
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
                        item.subtitles = subtitleTrackArray
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
                        item.subtitles = subtitleTrackArray
                        playbackItem = item;
                    }
                    
                    mediaPlayer.media = VLCMedia(url: playbackItem.videoUrl)
                    playbackItem.subtitles.forEach() { sub in
                        if(sub.id != -1 && sub.delivery == "External" && sub.codec != "subrip") {
                            mediaPlayer.addPlaybackSlave(sub.url, type: .subtitle, enforce: false)
                        }
                    }
                    mediaPlayer.play()
                    mediaPlayer.jumpForward(Int32(manifest.Progress/10000000))
                } catch {
                    
                }
                break
            case .failure(let error):
                debugPrint(error)
                break
            }
        }
        
        mediaPlayer.delegate = self
        mediaPlayer.drawable = videoContentView
        
        if(manifest.Type == "Episode") {
            titleLabel.text = "\(manifest.Name) -  S\(String(manifest.ParentIndexNumber ?? 0)):E\(String(manifest.IndexNumber ?? 0)) - \(manifest.SeriesName ?? "")"
        } else {
            titleLabel.text = manifest.Name
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
                print("Video is done playing)")
                sendStopReport()
            case .ended :
                print("Video is done playing)")
                sendStopReport()
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

/*
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
                if(sub.id != -1 && sub.delivery == "External" && sub.codec != "subrip") {
                    mediaPlayer.wrappedValue.addPlaybackSlave(sub.url, type: .subtitle, enforce: false)
                }
            }
            
            mediaPlayer.wrappedValue.perform(Selector(("setTextRendererFontSize:")), with: 14)
            //mediaPlayer.wrappedValue.perform(Selector(("setTextRendererFont:")), with: "Copperplate")
            
            DispatchQueue.global(qos: .utility).async { [weak self] in
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
 */
