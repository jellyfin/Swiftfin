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

protocol VideoPlayerSettingsDelegate: AnyObject {
    func selectNew(audioTrack id: Int32)
    func selectNew(subtitleTrack id: Int32)
}

class VideoPlayerViewController: UIViewController, VideoPlayerSettingsDelegate, VLCMediaPlayerDelegate, VLCMediaDelegate, UIGestureRecognizerDelegate  {


    @IBOutlet weak var videoContentView: UIView!
    @IBOutlet weak var controlsView: UIView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var transportBarView: UIView!
    @IBOutlet weak var scrubberView: UIView!
    @IBOutlet weak var scrubLabel: UILabel!
    @IBOutlet weak var gradientView: UIView!
    
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    
    @IBOutlet weak var infoViewContainer: UIView!
    
    var infoPanelDisplayPoint : CGPoint = .zero
    var infoPanelHiddenPoint : CGPoint = .zero
    
    var containerViewController: InfoTabBarViewController?
    var focusedOnTabBar : Bool = false
    var showingInfoPanel : Bool = false
    
    var mediaPlayer = VLCMediaPlayer()
    
    var lastProgressReportTime: Double = 0
    var lastTime: Float = 0.0
    var startTime: Int = 0
    
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
    var showingControls: Bool = false
    var loading: Bool = true
    
    var initialSeekPos : CGFloat = 0
    var videoPos: Double = 0
    var videoDuration: Double = 0
    var controlsAppearTime: Double = 0
    
    
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
        
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        
        mediaPlayer.delegate = self
        mediaPlayer.drawable = videoContentView
        
        if let runTimeTicks = manifest.runTimeTicks {
            videoDuration = Double(runTimeTicks / 10_000_000)
        }
        
        // Black gradient behind transport bar
        let gradientLayer:CAGradientLayer = CAGradientLayer()
        gradientLayer.frame.size = self.gradientView.frame.size
        gradientLayer.colors = [UIColor.black.withAlphaComponent(0.6).cgColor, UIColor.black.withAlphaComponent(0).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.0)
        self.gradientView.layer.addSublayer(gradientLayer)
        
        infoPanelDisplayPoint = infoViewContainer.center
        infoPanelHiddenPoint = CGPoint(x: infoPanelDisplayPoint.x, y: -infoViewContainer.frame.height)
        infoViewContainer.center = infoPanelHiddenPoint
        infoViewContainer.layer.cornerRadius = 40
        
        let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        blurEffectView.frame = infoViewContainer.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.layer.cornerRadius = 40
        blurEffectView.clipsToBounds = true
        infoViewContainer.addSubview(blurEffectView)
        infoViewContainer.sendSubviewToBack(blurEffectView)
        
        transportBarView.layer.cornerRadius = CGFloat(5)
        
        setupGestures()
        
        fetchVideo()
        
        setupNowPlayingCC()
        
        mediaPlayer.perform(Selector(("setTextRendererFontSize:")), with: 16)
        
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
                            
                            if stream.isDefault == true{
                                selectedCaptionTrack = Int32(stream.index!)
                            }
                            
                            if subtitle.delivery != .encode {
                                subtitleTrackArray.append(subtitle)
                            }
                        }
                        
                        if stream.type == .audio {
                            let track = AudioTrack(name: stream.displayTitle!, id: Int32(stream.index!))
                            
                            if stream.isDefault! == true {
                                selectedAudioTrack = Int32(stream.index!)
                            }
                            
                            audioTrackArray.append(track)
                        }
                    }
                    
                    // If no default audio tracks select the first one
                    if selectedAudioTrack == -1 && !audioTrackArray.isEmpty{
                        selectedAudioTrack = audioTrackArray.first!.id
                    }
                    
                    
                    self.sendPlayReport()
                    playbackItem = item
                    
                    mediaPlayer.media = VLCMedia(url: playbackItem.videoUrl)
                    mediaPlayer.media.delegate = self
                    mediaPlayer.play()
                    
                    // 1 second = 10,000,000 ticks
                    
                    if let rawStartTicks = manifest.userData?.playbackPositionTicks {
                        mediaPlayer.jumpForward(Int32(rawStartTicks / 10_000_000))
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
                    while mediaPlayer.numberOfSubtitlesTracks != shouldHaveSubtitleTracks {}
                    
                    // Select default track & resume playback
                    mediaPlayer.currentVideoSubTitleIndex = selectedCaptionTrack
                    mediaPlayer.pause()
                    mediaPlayer.play()
                    playing = true
                    
                    setupInfoPanel()
                    
                    activityIndicator.isHidden = true
                    loading = false
                    
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
        commandCenter.enableLanguageOptionCommand.isEnabled = true
        
        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { _ in
            self.pause()
            return .success
        }
        
        // Add handler for Play command
        commandCenter.playCommand.addTarget { _ in
            self.play()
            return .success
        }
        
        // Add handler for FF command
        commandCenter.seekForwardCommand.addTarget { _ in
            self.mediaPlayer.jumpForward(30)
            self.sendProgressReport(eventName: "timeupdate")
            return .success
        }
        
        // Add handler for RW command
        commandCenter.seekBackwardCommand.addTarget { _ in
            self.mediaPlayer.jumpBackward(15)
            self.sendProgressReport(eventName: "timeupdate")
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
                self.sendProgressReport(eventName: "unpause")
                
                return .success
            } else {
                return .commandFailed
            }
        }
        
//        commandCenter.enableLanguageOptionCommand.addTarget { [weak self](remoteEvent) in
//            guard let self = self else {return .commandFailed}
//
//
//
//        }
        
        var runTicks = 0
        var playbackTicks = 0
        
        if let ticks = manifest.runTimeTicks {
            runTicks = Int(ticks / 10_000_000)
        }
        
        if let ticks = manifest.userData?.playbackPositionTicks {
            playbackTicks = Int(ticks / 10_000_000)
        }
        
        var nowPlayingInfo = [String: Any]()

        nowPlayingInfo[MPMediaItemPropertyTitle] = manifest.name!
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] =  0.0
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = AVMediaType.video
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = runTicks
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = playbackTicks
        
        if let imageData = NSData(contentsOf: manifest.getPrimaryImage(maxWidth: 200)) {
            if let artworkImage = UIImage(data: imageData as Data) {
                let artwork = MPMediaItemArtwork.init(boundsSize: artworkImage.size, requestHandler: { (size) -> UIImage in
                        return artworkImage
                })
            nowPlayingInfo[MPMediaItemPropertyArtwork] =  artwork
                print("set artwork")
            }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    func updateNowPlayingCenter(time : Double?, playing : Bool?) {
        
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()

        if let playing = playing {
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = playing ? 1.0 : 0.0
        }
        if let time = time {
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = time
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

    }
    
    
    
    // Grabs a refference to the info panel view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "infoView" {
            containerViewController = segue.destination as? InfoTabBarViewController
            containerViewController?.videoPlayer = self
            
        }
    }
    
    // MARK: Player functions
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
        
        self.sendProgressReport(eventName: "pause")
        
        self.updateNowPlayingCenter(time: nil, playing: false)
        
        animateScrubber()
        
        self.scrubLabel.frame = CGRect(x: self.scrubberView.frame.minX - self.scrubLabel.frame.width/2, y:self.scrubLabel.frame.minY, width: self.scrubLabel.frame.width, height: self.scrubLabel.frame.height)
    }
    
    func play () {
        playing = true
        mediaPlayer.play()
        
        self.updateNowPlayingCenter(time: nil, playing: true)

        self.sendProgressReport(eventName: "unpause")
        
        animateScrubber()
    }
    
    
    func toggleInfoContainer() {
        showingInfoPanel.toggle()
        
        containerViewController?.view.isUserInteractionEnabled = showingInfoPanel
        
        if showingInfoPanel && seeking {
            scrubLabel.isHidden = true
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
                self.scrubberView.frame = CGRect(x: self.initialSeekPos, y: self.scrubberView.frame.minY, width: 2, height: self.scrubberView.frame.height)
            })
            seeking = false
            
        }
        
        UIView.animate(withDuration: 0.4, delay: 0,  options: .curveEaseOut) { [self] in
            infoViewContainer.center = showingInfoPanel ? infoPanelDisplayPoint : infoPanelHiddenPoint
        }
        
    }
    
    // MARK: Gestures
    func setupGestures() {
        
        let playPauseGesture = UITapGestureRecognizer(target: self, action: #selector(self.selectButtonTapped))
        let playPauseType = UIPress.PressType.playPause
        playPauseGesture.allowedPressTypes = [NSNumber(value: playPauseType.rawValue)];
        view.addGestureRecognizer(playPauseGesture)
        
        let selectGesture = UITapGestureRecognizer(target: self, action: #selector(self.selectButtonTapped))
        let selectType = UIPress.PressType.select
        selectGesture.allowedPressTypes = [NSNumber(value: selectType.rawValue)];
        view.addGestureRecognizer(selectGesture)
        
        let backTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.backButtonPressed(tap:)))
        let backPress = UIPress.PressType.menu
        backTapGesture.allowedPressTypes = [NSNumber(value: backPress.rawValue)];
        view.addGestureRecognizer(backTapGesture)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.userPanned(panGestureRecognizer:)))
        view.addGestureRecognizer(panGestureRecognizer)
        
        
        let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.swipe(swipe:)))
        swipeRecognizer.direction = .right
        view.addGestureRecognizer(swipeRecognizer)
        
        let swipeRecognizerl = UISwipeGestureRecognizer(target: self, action: #selector(self.swipe(swipe:)))
        swipeRecognizerl.direction = .left
        view.addGestureRecognizer(swipeRecognizerl)
        
    }
    
    @objc func backButtonPressed(tap : UITapGestureRecognizer) {
        
        // Dismiss info panel
        if showingInfoPanel {
            if focusedOnTabBar {
                toggleInfoContainer()
            }
            return
        }
        
        // Cancel seek and move back to initial position
        if(seeking) {
            scrubLabel.isHidden = true
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
                self.scrubberView.frame = CGRect(x: self.initialSeekPos, y: 0, width: 2, height: 10)
            })
            play()
            seeking = false
        }
        else
        {
            // Dismiss view
            mediaPlayer.stop()
            sendStopReport()
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func userPanned(panGestureRecognizer : UIPanGestureRecognizer) {
        if loading {
            return
        }
        
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
            self.scrubLabel.frame = CGRect(x: (newPos - self.scrubLabel.frame.width/2), y: self.scrubLabel.frame.minY, width: self.scrubLabel.frame.width, height: self.scrubLabel.frame.height)
            self.scrubLabel.text = (self.formatSecondsToHMS(time))
            
        })
        
        
    }
    
    // Not currently used
    @objc func swipe(swipe: UISwipeGestureRecognizer!) {
        print("swiped")
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
        if loading {
            return
        }
        
        showingControls = true
        controlsView.isHidden = false
        controlsAppearTime = CACurrentMediaTime()
        
        
        // Move to seeked position
        if(seeking) {
            scrubLabel.isHidden = true
            
            // Move current time to the scrubbed position
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: { [self] in
                
                self.currentTimeLabel.frame = CGRect(x: CGFloat(scrubLabel.frame.minX + transportBarView.frame.minX), y: currentTimeLabel.frame.minY, width: currentTimeLabel.frame.width, height: currentTimeLabel.frame.height)
                
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
    
    
    // MARK: Jellyfin Playstate updates
    func sendProgressReport(eventName: String) {
        if (eventName == "timeupdate" && mediaPlayer.state == .playing) || eventName != "timeupdate" {
            let progressInfo = PlaybackProgressInfo(canSeek: true, item: manifest, itemId: manifest.id, sessionId: playSessionId, mediaSourceId: manifest.id, audioStreamIndex: Int(selectedAudioTrack), subtitleStreamIndex: Int(selectedCaptionTrack), isPaused: (!playing), isMuted: false, positionTicks: Int64(mediaPlayer.position * Float(manifest.runTimeTicks!)), playbackStartTimeTicks: Int64(startTime), volumeLevel: 100, brightness: 100, aspectRatio: nil, playMethod: playbackItem.videoType, liveStreamId: nil, playSessionId: playSessionId, repeatMode: .repeatNone, nowPlayingQueue: [], playlistItemId: "playlistItem0")
            
            PlaystateAPI.reportPlaybackProgress(playbackProgressInfo: progressInfo)
                .sink(receiveCompletion: { result in
                    print(result)
                }, receiveValue: { _ in
                    print("Playback progress report sent!")
                })
                .store(in: &cancellables)
        }
    }
    
    func sendStopReport() {
        let stopInfo = PlaybackStopInfo(item: manifest, itemId: manifest.id, sessionId: playSessionId, mediaSourceId: manifest.id, positionTicks: Int64(mediaPlayer.position * Float(manifest.runTimeTicks!)), liveStreamId: nil, playSessionId: playSessionId, failed: nil, nextMediaType: nil, playlistItemId: "playlistItem0", nowPlayingQueue: [])
        
        PlaystateAPI.reportPlaybackStopped(playbackStopInfo: stopInfo)
            .sink(receiveCompletion: { result in
                print(result)
            }, receiveValue: { _ in
                print("Playback stop report sent!")
            })
            .store(in: &cancellables)
    }
    
    func sendPlayReport() {
        startTime = Int(Date().timeIntervalSince1970) * 10000000
        
        print("sending play report!")
        
        let startInfo = PlaybackStartInfo(canSeek: true, item: manifest, itemId: manifest.id, sessionId: playSessionId, mediaSourceId: manifest.id, audioStreamIndex: Int(selectedAudioTrack), subtitleStreamIndex: Int(selectedCaptionTrack), isPaused: false, isMuted: false, positionTicks: manifest.userData?.playbackPositionTicks, playbackStartTimeTicks: Int64(startTime), volumeLevel: 100, brightness: 100, aspectRatio: nil, playMethod: playbackItem.videoType, liveStreamId: nil, playSessionId: playSessionId, repeatMode: .repeatNone, nowPlayingQueue: [], playlistItemId: "playlistItem0")
        
        PlaystateAPI.reportPlaybackStart(playbackStartInfo: startInfo)
            .sink(receiveCompletion: { result in
                print(result)
            }, receiveValue: { _ in
                print("Playback start report sent!")
            })
            .store(in: &cancellables)
    }
    
    
    // MARK: VLC Delegate
    
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        let currentState: VLCMediaPlayerState = mediaPlayer.state
        switch currentState {
        case .buffering:
            print("Video is buffering")
            loading = true
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            mediaPlayer.pause()
            usleep(10000)
            mediaPlayer.play()
            break
        case .stopped:
            print("stopped")
            
            break
        case .ended:
            print("ended")
            
            break
        case .opening:
            print("opening")
            
            break
        case .paused:
            print("paused")
            
            break
        case .playing:
            print("Video is playing")
            loading = false
            sendProgressReport(eventName: "unpause")
            DispatchQueue.main.async { [self] in
                activityIndicator.isHidden = true
                activityIndicator.stopAnimating()
            }
            playing = true
            break
        case .error:
            print("error")
            break
        case .esAdded:
            print("esAdded")
            break
        default:
            print("default")
            break
            
        }
        
    }
    
    // Move time along transport bar
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        
        if loading {
            loading = false
            DispatchQueue.main.async { [self] in
                activityIndicator.isHidden = true
                activityIndicator.stopAnimating()
            }
            updateNowPlayingCenter(time: nil, playing: true)
        }
        
        let time = mediaPlayer.position
        if time != lastTime {
            self.currentTimeLabel.text = formatSecondsToHMS(Double(mediaPlayer.time.intValue/1000))
            self.remainingTimeLabel.text = "-" + formatSecondsToHMS(Double(abs(mediaPlayer.remainingTime.intValue/1000)))
            
            self.videoPos = Double(mediaPlayer.position)
            
            let newPos = videoPos * Double(self.transportBarView.frame.width)
            if !newPos.isNaN && self.playing {
                self.scrubberView.frame = CGRect(x: newPos, y: 0, width: 2, height: 10)
                self.currentTimeLabel.frame = CGRect(x: CGFloat(newPos) + transportBarView.frame.minX - currentTimeLabel.frame.width/2, y: currentTimeLabel.frame.minY, width: currentTimeLabel.frame.width, height: currentTimeLabel.frame.height)
            }
            
            if showingControls {
                if CACurrentMediaTime() - controlsAppearTime > 5 {
                    showingControls = false
                    UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                        self.controlsView.alpha = 0.0
                    }, completion: { (_: Bool) in
                        self.controlsView.isHidden = true
                        self.controlsView.alpha = 1
                    })
                    controlsAppearTime = 999_999_999_999_999
                }
            }
            
        }
        
        lastTime = time
        
        if CACurrentMediaTime() - lastProgressReportTime > 5 {
            sendProgressReport(eventName: "timeupdate")
            lastProgressReportTime = CACurrentMediaTime()
        }
    }
    
    
    // MARK: Settings Delegate
    func selectNew(audioTrack id: Int32) {
        selectedAudioTrack = id
        mediaPlayer.currentAudioTrackIndex = id
    }
    
    func selectNew(subtitleTrack id: Int32) {
        selectedCaptionTrack = id
        mediaPlayer.currentVideoSubTitleIndex = id
    }
    
    func setupInfoPanel() {
        containerViewController?.setupInfoViews(mediaItem: manifest, subtitleTracks: subtitleTrackArray, selectedSubtitleTrack: selectedCaptionTrack, audioTracks: audioTrackArray, selectedAudioTrack: selectedAudioTrack, delegate: self)
    }
    
    
    func formatSecondsToHMS(_ seconds: Double) -> String {
        let timeHMSFormatter: DateComponentsFormatter = {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .positional
            formatter.allowedUnits = seconds >= 3600 ?
                [.hour, .minute, .second] :
                [.minute, .second]
            formatter.zeroFormattingBehavior = .pad
            return formatter
        }()
        
        guard !seconds.isNaN,
              let text = timeHMSFormatter.string(from: seconds) else {
            return "00:00"
        }
        
        return text.hasPrefix("0") && text.count > 4 ?
            .init(text.dropFirst()) : text
    }
    
    // When VLC video starts playing a real device can no longer receive gesture recognisers, adding this in hopes to fix the issue but no luck
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        print("recognisesimultaneousvideoplayer")
        return true
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
