//
//  VideoPlayerViewController.swift
//  CustomPlayer
//
//  Created by Stephen Byatt on 15/6/21.
//

import TVUIKit
import TVVLCKit
import MediaPlayer
import JellyfinAPI
import Combine

struct Subtitle {
    var name: String
    var id: Int32
    var url: URL?
    var delivery: SubtitleDeliveryMethod
    var codec: String
}

struct AudioTrack {
    var name: String
    var id: Int32
}

class PlaybackItem: ObservableObject {
    @Published var videoType: PlayMethod = .directPlay
    @Published var videoUrl: URL = URL(string: "https://example.com")!
}


class VideoPlayerViewController: UIViewController, VLCMediaPlayerDelegate, VLCMediaDelegate, UIGestureRecognizerDelegate  {
    
    @IBOutlet weak var videoContentView: UIView!
    @IBOutlet weak var controlsView: UIView!
    
    @IBOutlet weak var transportBarView: UIView!
    @IBOutlet weak var scrubberView: UIView!
    @IBOutlet weak var scrubLabel: UILabel!
    
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    
    @IBOutlet weak var infoViewContainer: UIView!
    var infoPanelDisplayPoint : CGPoint = .zero
    var infoPanelHiddenPoint : CGPoint = .zero
    
    var containerViewController: InfoTabBarViewController?
    var focusedOnTabBar : Bool = false
    var showingInfoPanel : Bool = false
    
    var mediaPlayer = VLCMediaPlayer()
    
    var selectedAudioTrack: Int32 = -1 {
        didSet {
            print(selectedAudioTrack)
        }
    }
    var selectedCaptionTrack: Int32 = -1 {
        didSet {
            print(selectedCaptionTrack)
        }
    }
    
    var subtitleTrackArray: [Subtitle] = []
    var audioTrackArray: [AudioTrack] = []

    var playing: Bool = false
    var seeking: Bool = false
    
    var initialSeekPos : CGFloat = 0
    var videoPos: Double = 0
    var videoDuration: Double = 0
    
    var manifest: BaseItemDto = BaseItemDto()
    var playbackItem = PlaybackItem()
    var playSessionId: String = ""

    var cancellables = Set<AnyCancellable>()

        
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        
        super.didUpdateFocus(in: context, with: coordinator)
        
        // Check if focused on the tab bar, allows for swipe up to dismiss the info panel
        if context.nextFocusedView!.description.contains("UITabBarButton")
        {
            // Set value after half a second so info panel is not dismissed instantly when swiping up from content
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.focusedOnTabBar  = true
            }
        }
        else
        {
            focusedOnTabBar = false
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        mediaPlayer.delegate = self
        mediaPlayer.drawable = videoContentView
        
        setPlayerMedia()
        
        infoPanelDisplayPoint = infoViewContainer.center
        infoPanelHiddenPoint = CGPoint(x: infoPanelDisplayPoint.x, y: -infoViewContainer.frame.height)
        infoViewContainer.center = infoPanelHiddenPoint
        infoViewContainer.layer.cornerRadius = 40
        
        transportBarView.layer.cornerRadius = CGFloat(5)
        transportBarView.backgroundColor = .darkGray
        transportBarView.clipsToBounds = false
        
        scrubLabel.font = UIFont.systemFont(ofSize: 30)
        scrubLabel.textAlignment = .center
        scrubLabel.isHidden = true
        
        remainingTimeLabel.font = UIFont.systemFont(ofSize: 30)
        remainingTimeLabel.textAlignment = .right
        
        currentTimeLabel.font = UIFont.systemFont(ofSize: 30)
        currentTimeLabel.textAlignment = .center
        
        setupGestures()
        
        fetchVideo()
        
        setupNowPlayingCC()
        
        play()
        
    }
    
    func fetchVideo() {
        // Fetch max bitrate from UserDefaults depending on current connection mode
        let defaults = UserDefaults.standard
        let maxBitrate = defaults.integer(forKey: "InNetworkBandwidth")

        // Build a device profile
        let builder = DeviceProfileBuilder()
        builder.setMaxBitrate(bitrate: maxBitrate)
        let profile = builder.buildProfile()

        let playbackInfo = PlaybackInfoDto(userId: SessionManager.current.user.user_id!, maxStreamingBitrate: Int(maxBitrate), startTimeTicks: manifest.userData?.playbackPositionTicks ?? 0, deviceProfile: profile, autoOpenLiveStream: true)

        DispatchQueue.global(qos: .userInitiated).async { [self] in
//            delegate?.showLoadingView(self)
            MediaInfoAPI.getPostedPlaybackInfo(itemId: manifest.id!, userId: SessionManager.current.user.user_id!, maxStreamingBitrate: Int(maxBitrate), startTimeTicks: manifest.userData?.playbackPositionTicks ?? 0, autoOpenLiveStream: true, playbackInfoDto: playbackInfo)
                .sink(receiveCompletion: { result in
                    print(result)
                }, receiveValue: { [self] response in
                    
                    videoContentView.setNeedsLayout()
                    videoContentView.setNeedsDisplay()
                    
                    playSessionId = response.playSessionId ?? ""
                    
                    let mediaSource = response.mediaSources!.first.self!
                    
                    let item = PlaybackItem()
                    let streamURL : URL?
                    
                    // Item is being transcoded by request of server
                    if mediaSource.transcodingUrl != nil
                    {
                        item.videoType = .transcode
                        streamURL = URL(string: "\(ServerEnvironment.current.server.baseURI!)\(mediaSource.transcodingUrl!)")
                    }
                    // Item will be directly played by the client
                    else
                    {
                        item.videoType = .directPlay
                        streamURL = URL(string: "\(ServerEnvironment.current.server.baseURI!)/Videos/\(manifest.id!)/stream?Static=true&mediaSourceId=\(manifest.id!)&deviceId=\(SessionManager.current.deviceID)&api_key=\(SessionManager.current.accessToken)&Tag=\(mediaSource.eTag!)")!
                    }
                    
                    item.videoUrl = streamURL!
                    
                    let disableSubtitleTrack = Subtitle(name: "None", id: -1, url: nil, delivery: .embed, codec: "")
                    subtitleTrackArray.append(disableSubtitleTrack)
                    
                    // Loop through media streams and add to array
                    for stream in mediaSource.mediaStreams! {
                        if stream.type == .subtitle {
                            var deliveryUrl: URL? = nil
                            
                            if stream.deliveryMethod == .external {
                                deliveryUrl = URL(string: "\(ServerEnvironment.current.server.baseURI!)\(stream.deliveryUrl!)")!
                            }
                            
                            let subtitle = Subtitle(name: stream.displayTitle ?? "Unknown", id: Int32(stream.index!), url: deliveryUrl, delivery: stream.deliveryMethod!, codec: stream.codec ?? "webvtt")

                            if subtitle.delivery != .encode {
                                subtitleTrackArray.append(subtitle)
                            }
                        }

                        if stream.type == .audio {
                            let subtitle = AudioTrack(name: stream.displayTitle!, id: Int32(stream.index!))
                            if stream.isDefault! == true {
                                selectedAudioTrack = Int32(stream.index!)
                            }
                            audioTrackArray.append(subtitle)
                        }
                    }

                    // If no default audio tracks select the first one
                    if selectedAudioTrack == -1 && !audioTrackArray.isEmpty{
                        selectedAudioTrack = audioTrackArray.first!.id
                    }

//                        self.sendPlayReport()
                    playbackItem = item

                    mediaPlayer.media = VLCMedia(url: playbackItem.videoUrl)
                    mediaPlayer.media.delegate = self
                    mediaPlayer.play()

                    // 1 second = 10,000,000 ticks

                    let rawStartTicks = manifest.userData?.playbackPositionTicks ?? 0

                    if rawStartTicks != 0 {
                        let startSeconds = rawStartTicks / 10_000_000
                        mediaPlayer.jumpForward(Int32(startSeconds))
                    }

                    // Pause and load captions into memory.
                    mediaPlayer.pause()

                    var shouldHaveSubtitleTracks = 0
                    subtitleTrackArray.forEach { sub in
                        if sub.id != -1 && sub.delivery == .external && sub.codec != "subrip" {
                            shouldHaveSubtitleTracks = shouldHaveSubtitleTracks + 1
                            mediaPlayer.addPlaybackSlave(sub.url!, type: .subtitle, enforce: false)
                        }
                    }

                    // Wait for captions to load
//                    delegate?.showLoadingView(self)

                    while mediaPlayer.numberOfSubtitlesTracks != shouldHaveSubtitleTracks {}

                    // Select default track & resume playback
                    mediaPlayer.currentVideoSubTitleIndex = selectedCaptionTrack
                    mediaPlayer.pause()
                    mediaPlayer.play()
                })
                .store(in: &cancellables)
        }
    }
    
    func setupNowPlayingCC() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.seekForwardCommand.isEnabled = true
        commandCenter.seekBackwardCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { _ in
            self.pause()
//            self.sendProgressReport(eventName: "pause")
            return .success
        }

        // Add handler for Play command
        commandCenter.playCommand.addTarget { _ in
            self.play()
            //            self.sendProgressReport(eventName: "unpause")
            return .success
        }

        // Add handler for FF command
        commandCenter.seekForwardCommand.addTarget { _ in
            self.mediaPlayer.jumpForward(30)
//            self.sendProgressReport(eventName: "timeupdate")
            return .success
        }

        // Add handler for RW command
        commandCenter.seekBackwardCommand.addTarget { _ in
            self.mediaPlayer.jumpBackward(15)
//            self.sendProgressReport(eventName: "timeupdate")
            return .success
        }

        // Scrubber
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self](remoteEvent) -> MPRemoteCommandHandlerStatus in
            guard let self = self else {return .commandFailed}

            if let event = remoteEvent as? MPChangePlaybackPositionCommandEvent {
                let targetSeconds = event.positionTime

                let videoPosition = Double(self.mediaPlayer.time.intValue)
                let offset = targetSeconds - videoPosition
                if offset > 0 {
                    self.mediaPlayer.jumpForward(Int32(offset)/1000)
                } else {
                    self.mediaPlayer.jumpBackward(Int32(abs(offset))/1000)
                }
//                self.sendProgressReport(eventName: "unpause")

                return .success
            } else {
                return .commandFailed
            }
        }

        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: "TestVideo",
            MPNowPlayingInfoPropertyPlaybackRate : 0,
            MPNowPlayingInfoPropertyMediaType : AVMediaType.video
        ]

        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    // When VLC video starts playing a real device can no longer receive gesture recognisers, adding this in hopes to fix the issue but no luck
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        print("recognisesimultaneousvideoplayer")
        return true
    }
    
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        let currentState: VLCMediaPlayerState = mediaPlayer.state
        switch currentState {
        case .buffering:
            break
        case .stopped:
            break
        case .ended:
            break
        case .opening:
            break
        case .paused:
            break
        case .playing:
            break
        case .error:
            break
        case .esAdded:
            // esAdded is called 3 times, need to wait til 3rd time when video stream is added to play the video
            print("es added")
            if videoDuration == 0 && mediaPlayer.remainingTime.intValue != 0 {
                videoDuration = Double(abs(mediaPlayer.remainingTime.intValue)/1000)
                
                print(videoDuration)
                var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
                info[MPMediaItemPropertyPlaybackDuration] = videoDuration
                info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = mediaPlayer.position
                info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            }
            break
        default:
            print("default")
            break
            
        }
        
    }
    
    // Move time along transport bar
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        
        self.currentTimeLabel.text = formatSecondsToHMS(Double(mediaPlayer.time.intValue/1000))
        self.remainingTimeLabel.text = "-" + formatSecondsToHMS(Double(abs(mediaPlayer.remainingTime.intValue/1000)))

        self.videoPos = Double(mediaPlayer.position)
    
        let newPos = videoPos * Double(self.transportBarView.frame.width)
        if !newPos.isNaN && self.playing {
            self.scrubberView.frame = CGRect(x: newPos, y: 0, width: 2, height: 10)
            self.currentTimeLabel.frame = CGRect(x: CGFloat(newPos)+50, y: currentTimeLabel.frame.minY, width: currentTimeLabel.frame.width, height: currentTimeLabel.frame.height)
            
        }
    }
    
    // Use this method to fetch the video to play
    public func setPlayerMedia() {
        let media = VLCMedia(url: URL(string: "https://multiplatform-f.akamaihd.net/i/multi/will/bunny/big_buck_bunny_,640x360_400,640x360_700,640x360_1000,950x540_1500,.f4v.csmil/master.m3u8")!)
        mediaPlayer.media = media
        mediaPlayer.media.delegate = self
        
    }
    
    // Grabs a refference to the info panel view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "infoView" {
            containerViewController = segue.destination as? InfoTabBarViewController
            containerViewController?.videoPlayer = self

        }
    }
    
    // Animate the scrubber when playing state changes
    func animateScrubber() {
        let y : CGFloat = playing ? 0 : -20
        let height: CGFloat = playing ? 10 : 30
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
            self.scrubberView.frame = CGRect(x: self.scrubberView.frame.minX, y: y, width: 2, height: height)
        })
    }
    
    
    func pause() {
        playing = false
        mediaPlayer.pause()
        
        animateScrubber()
                
        self.scrubLabel.frame = CGRect(x: self.scrubberView.frame.minX - self.scrubLabel.frame.width/2, y: -90,
                                       width: self.scrubLabel.frame.width, height: self.scrubLabel.frame.height)
    }
    
    func play () {
        playing = true
        mediaPlayer.play()
        
        animateScrubber()
    }
    
    
    func toggleInfoContainer() {
        showingInfoPanel.toggle()
        
        containerViewController?.view.isUserInteractionEnabled = showingInfoPanel
        
        UIView.animate(withDuration: 0.4, delay: 0,  options: .curveEaseOut) { [self] in
            infoViewContainer.center = showingInfoPanel ? infoPanelDisplayPoint : infoPanelHiddenPoint
        }

    }
    
    
    func setupGestures() {
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.selectButtonTapped))
        let pressType = UIPress.PressType.playPause
        tapGestureRecognizer.allowedPressTypes = [NSNumber(value: pressType.rawValue)];
        view.addGestureRecognizer(tapGestureRecognizer)

        
        let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.swipe(swipe:)))
        swipeRecognizer.direction = .right
        view.addGestureRecognizer(swipeRecognizer)
        
        let swipeRecognizerl = UISwipeGestureRecognizer(target: self, action: #selector(self.swipe(swipe:)))
        swipeRecognizerl.direction = .left
        view.addGestureRecognizer(swipeRecognizerl)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.userPanned(panGestureRecognizer:)))
        view.addGestureRecognizer(panGestureRecognizer)
        
        let touchGesture = UITapGestureRecognizer(target: self, action: #selector(self.selectButtonTapped))
        let touchType = UIPress.PressType.select
        touchGesture.allowedPressTypes = [NSNumber(value: touchType.rawValue)];
        view.addGestureRecognizer(touchGesture)

        let backTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.backButtonPressed(tap:)))
        let backPress = UIPress.PressType.menu
        backTapGesture.allowedPressTypes = [NSNumber(value: backPress.rawValue)];
        view.addGestureRecognizer(backTapGesture)

    }
    
    @objc func backButtonPressed(tap : UITapGestureRecognizer) {
        // Cancel seek and move back to initial position
        if(seeking) {
            scrubLabel.isHidden = true
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
                self.scrubberView.frame = CGRect(x: self.initialSeekPos, y: 0, width: 2, height: 10)
            })
            play()
            seeking = false
        }
    }
    
    @objc func userPanned(panGestureRecognizer : UIPanGestureRecognizer) {
        
        let translation = panGestureRecognizer.translation(in: view)
        let velocity = panGestureRecognizer.velocity(in: view)
        
        // Swiped up - Handle dismissing info panel
        if translation.y < -700 && (focusedOnTabBar && showingInfoPanel) {
            toggleInfoContainer()
            return
        }

        if showingInfoPanel {
            return
        }
        
        // Swiped down - Show the info panel
        if translation.y > 700 {
            toggleInfoContainer()
            return
        }
        
        // Ignore seek if video is playing
        if playing {
            return
        }
        
        // Save current position if seek is cancelled and show the scrubLabel
        if(!seeking) {
            initialSeekPos = self.scrubberView.frame.minX
            seeking = true
            self.scrubLabel.isHidden = false
        }
        
        let newPos = (self.scrubberView.frame.minX + velocity.x/100).clamped(to: 0...transportBarView.frame.width)
        
        UIView.animate(withDuration: 0.8, delay: 0, options: .curveEaseOut, animations: {
            let time = (Double(self.scrubberView.frame.minX) * self.videoDuration) / Double(self.transportBarView.frame.width)
            
            self.scrubberView.frame = CGRect(x: newPos, y: self.scrubberView.frame.minY, width: 2, height: 30)
            self.scrubLabel.frame = CGRect(x: newPos - 50, y: -90, width: self.scrubLabel.frame.width, height: self.scrubLabel.frame.height)
            self.scrubLabel.text = (self.formatSecondsToHMS(time))
            
        })
        
        
    }
    
    // Not currently used
    @objc func swipe(swipe: UISwipeGestureRecognizer!) {
        print(swipe.location(in: view))
        switch swipe.direction {
        case .left:
            print("swiped left")
            mediaPlayer.pause()
            //            player.seek(to: CMTime(value: Int64(self.currentSeconds) + 10, timescale: 1))
            mediaPlayer.play()
        case .right:
            print("swiped right")
            mediaPlayer.pause()
            //            player.seek(to: CMTime(value: Int64(self.currentSeconds) + 10, timescale: 1))
            mediaPlayer.play()
        case .up:
            break
        case .down:
            break
        default:
            break
        }
        
    }
    
    /// Play/Pause or Select is pressed on the AppleTV remote
    @objc func selectButtonTapped() {
        
        // Move to seeked position
        if(seeking) {
            scrubLabel.isHidden = true
                        
            // Move current time to the scrubbed position
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: { [self] in
                self.currentTimeLabel.frame = CGRect(x: CGFloat(scrubberView.frame.minX) + 50, y: currentTimeLabel.frame.minY, width: currentTimeLabel.frame.width, height: currentTimeLabel.frame.height)
            })
            
            let time = (Double(self.scrubberView.frame.minX) * self.videoDuration) / Double(self.transportBarView.frame.width)

            self.currentTimeLabel.text = self.scrubLabel.text
            self.remainingTimeLabel.text = "-" + formatSecondsToHMS(videoDuration - time)
            
            mediaPlayer.position = Float(self.scrubberView.frame.minX) / Float(self.transportBarView.frame.width)
            
            play()
            
            seeking = false
            return
        }
        
        playing ? pause() : play()
    }
    
    
    
    private var timeHMSFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter
    }()
    
    func formatSecondsToHMS(_ seconds: Double) -> String {
        guard !seconds.isNaN,
              let text = timeHMSFormatter.string(from: seconds) else {
            return "00:00"
        }
        
        return text
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
