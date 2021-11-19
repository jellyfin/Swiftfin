//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import TVUIKit
import TVVLCKit
import MediaPlayer
import JellyfinAPI
import Combine
import Defaults

protocol VideoPlayerSettingsDelegate: AnyObject {
    func selectNew(audioTrack id: Int32)
    func selectNew(subtitleTrack id: Int32)
}

class VideoPlayerViewController: UIViewController, VideoPlayerSettingsDelegate, VLCMediaPlayerDelegate, VLCMediaDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var videoContentView: UIView!
    @IBOutlet weak var controlsView: UIView!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var transportBarView: UIView!
    @IBOutlet weak var scrubberView: UIView!
    @IBOutlet weak var scrubLabel: UILabel!
    @IBOutlet weak var gradientView: UIView!

    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!

    @IBOutlet weak var infoPanelContainerView: UIView!

    var infoTabBarViewController: InfoTabBarViewController?
    var focusedOnTabBar: Bool = false
    var showingInfoPanel: Bool = false

    var mediaPlayer = VLCMediaPlayer()

    var lastProgressReportTime: Double = 0
    var lastTime: Float = 0.0
    var startTime: Int = 0

    var selectedAudioTrack: Int32 = -1
    var selectedCaptionTrack: Int32 = -1

    var subtitleTrackArray: [Subtitle] = []
    var audioTrackArray: [AudioTrack] = []

    var playing: Bool = false
    var seeking: Bool = false
    var showingControls: Bool = false
    var loading: Bool = true

    var initialSeekPos: CGFloat = 0
    var videoPos: Double = 0
    var videoDuration: Double = 0
    var controlsAppearTime: Double = 0

    var manifest: BaseItemDto = BaseItemDto()
    var playbackItem = PlaybackItem()
    var playSessionId: String = ""
    var backAction = {}

    var cancellables = Set<AnyCancellable>()

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {

        super.didUpdateFocus(in: context, with: coordinator)

        // Check if focused on the tab bar, allows for swipe up to dismiss the info panel
      if let nextFocused = context.nextFocusedView,
         nextFocused.description.contains("UITabBarButton") {
            // Set value after half a second so info panel is not dismissed instantly when swiping up from content
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.focusedOnTabBar  = true
            }
        } else {
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
        let gradientLayer: CAGradientLayer = CAGradientLayer()
        gradientLayer.frame.size = self.gradientView.frame.size
        gradientLayer.colors = [UIColor.black.withAlphaComponent(0.6).cgColor, UIColor.black.withAlphaComponent(0).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.0)
        self.gradientView.layer.addSublayer(gradientLayer)

        infoPanelContainerView.center = CGPoint(x: infoPanelContainerView.center.x, y: -infoPanelContainerView.frame.height)
        infoPanelContainerView.layer.cornerRadius = 40

        let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        blurEffectView.frame = infoPanelContainerView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.layer.cornerRadius = 40
        blurEffectView.clipsToBounds = true
        infoPanelContainerView.addSubview(blurEffectView)
        infoPanelContainerView.sendSubviewToBack(blurEffectView)

        transportBarView.layer.cornerRadius = CGFloat(5)

        setupGestures()

        fetchVideo()

        setupNowPlayingCC()

        // Adjust subtitle size
        mediaPlayer.perform(Selector(("setTextRendererFontSize:")), with: 16)

    }

    func fetchVideo() {
        // Fetch max bitrate from UserDefaults depending on current connection mode
        let maxBitrate = Defaults[.inNetworkBandwidth]

        // Build a device profile
        let builder = DeviceProfileBuilder()
        builder.setMaxBitrate(bitrate: maxBitrate)
        let profile = builder.buildProfile()

        let currentUser = SessionManager.main.currentLogin.user

        let playbackInfo = PlaybackInfoDto(userId: currentUser.id, maxStreamingBitrate: Int(maxBitrate), startTimeTicks: manifest.userData?.playbackPositionTicks ?? 0, deviceProfile: profile, autoOpenLiveStream: true)

        DispatchQueue.global(qos: .userInitiated).async { [self] in
            MediaInfoAPI.getPostedPlaybackInfo(itemId: manifest.id!, userId: currentUser.id, maxStreamingBitrate: Int(maxBitrate), startTimeTicks: manifest.userData?.playbackPositionTicks ?? 0, autoOpenLiveStream: true, playbackInfoDto: playbackInfo)
                .sink(receiveCompletion: { result in
                    print(result)
                }, receiveValue: { [self] response in

                    videoContentView.setNeedsLayout()
                    videoContentView.setNeedsDisplay()

                    playSessionId = response.playSessionId ?? ""

                    guard let mediaSource = response.mediaSources?.first.self else {
                        return
                    }

                    let item = PlaybackItem()
                    let streamURL: URL

                    // Item is being transcoded by request of server
                    if let transcodiungUrl = mediaSource.transcodingUrl {
                        item.videoType = .transcode
                        streamURL = URL(string: "\(SessionManager.main.currentLogin.server.uri)\(transcodiungUrl)")!
                    }
                    // Item will be directly played by the client
                    else {
                        item.videoType = .directPlay
//                        streamURL = URL(string: "\(SessionManager.main.currentLogin.server.uri)/Videos/\(manifest.id!)/stream?Static=true&mediaSourceId=\(manifest.id!)&deviceId=\(SessionManager.current.deviceID)&api_key=\(SessionManager.current.accessToken)&Tag=\(mediaSource.eTag!)")!
                        streamURL = URL(string: "\(SessionManager.main.currentLogin.server.uri)/Videos/\(manifest.id!)/stream?Static=true&mediaSourceId=\(manifest.id!)&Tag=\(mediaSource.eTag ?? "")")!
                    }

                    item.videoUrl = streamURL

                    let disableSubtitleTrack = Subtitle(name: "None", id: -1, url: nil, delivery: .embed, codec: "", languageCode: "")
                    subtitleTrackArray.append(disableSubtitleTrack)

                    // Loop through media streams and add to array
                    for stream in mediaSource.mediaStreams! {

                        if stream.type == .subtitle {
                            var deliveryUrl: URL?

                            if stream.deliveryMethod == .external {
                                deliveryUrl = URL(string: "\(SessionManager.main.currentLogin.server.uri)\(stream.deliveryUrl!)")!
                            }

                            let subtitle = Subtitle(name: stream.displayTitle ?? "Unknown", id: Int32(stream.index!), url: deliveryUrl, delivery: stream.deliveryMethod!, codec: stream.codec ?? "webvtt", languageCode: stream.language ?? "")

                            if stream.isDefault == true {
                                selectedCaptionTrack = Int32(stream.index!)
                            }

                            if subtitle.delivery != .encode {
                                subtitleTrackArray.append(subtitle)
                            }
                        }

                        if stream.type == .audio {
                            let track = AudioTrack(name: stream.displayTitle!, languageCode: stream.language ?? "", id: Int32(stream.index!))

                            if stream.isDefault! == true {
                                selectedAudioTrack = Int32(stream.index!)
                            }

                            audioTrackArray.append(track)
                        }
                    }

                    // If no default audio tracks select the first one
                    if selectedAudioTrack == -1 && !audioTrackArray.isEmpty {
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

                    subtitleTrackArray.forEach { sub in
                        if sub.id != -1 && sub.delivery == .external && sub.codec != "subrip" {
                            mediaPlayer.addPlaybackSlave(sub.url!, type: .subtitle, enforce: false)
                        }
                    }

                    playing = true
                    setupInfoPanel()

                })
                .store(in: &cancellables)

        }
    }

    func setupNowPlayingCC() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true

        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]

        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [30]

        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.enableLanguageOptionCommand.isEnabled = true

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { _ in
            self.pause()
            self.showingControls = true
            self.controlsView.isHidden = false
            self.controlsAppearTime = CACurrentMediaTime()
            return .success
        }

        // Add handler for Play command
        commandCenter.playCommand.addTarget { _ in
            self.play()
            self.showingControls = false
            self.controlsView.isHidden = true
            return .success
        }

        // Add handler for FF command
        commandCenter.skipForwardCommand.addTarget { _ in
            self.mediaPlayer.jumpForward(30)
            self.sendProgressReport(eventName: "timeupdate")
            return .success
        }

        // Add handler for RW command
        commandCenter.skipBackwardCommand.addTarget { _ in
            self.mediaPlayer.jumpBackward(15)
            self.sendProgressReport(eventName: "timeupdate")
            return .success
        }

        // Scrubber
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self](remoteEvent) -> MPRemoteCommandHandlerStatus in
            guard let self = self else {return .commandFailed}

            if let event = remoteEvent as? MPChangePlaybackPositionCommandEvent {
                let targetSeconds = event.positionTime
                let videoPosition = Double(self.mediaPlayer.time.intValue / 1000)
                let offset = targetSeconds - videoPosition

                if offset > 0 {
                    self.mediaPlayer.jumpForward(Int32(offset))
                } else {
                    self.mediaPlayer.jumpBackward(Int32(abs(offset)))
                }
                self.sendProgressReport(eventName: "unpause")

                return .success
            } else {
                return .commandFailed
            }
        }

        var runTicks = 0
        var playbackTicks = 0

        if let ticks = manifest.runTimeTicks {
            runTicks = Int(ticks / 10_000_000)
        }

        if let ticks = manifest.userData?.playbackPositionTicks {
            playbackTicks = Int(ticks / 10_000_000)
        }

        var nowPlayingInfo = [String: Any]()

        nowPlayingInfo[MPMediaItemPropertyTitle] = manifest.name ?? "Jellyfin Video"
        if manifest.type == "Episode" {
            nowPlayingInfo[MPMediaItemPropertyArtist] = "\(manifest.seriesName ?? manifest.name ?? "") • \(manifest.getEpisodeLocator())"
        }
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] =  0.0
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = AVMediaType.video
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = runTicks
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = playbackTicks

        if let imageData = NSData(contentsOf: manifest.getPrimaryImage(maxWidth: 500)) {
            if let artworkImage = UIImage(data: imageData as Data) {
                let artwork = MPMediaItemArtwork.init(boundsSize: artworkImage.size, requestHandler: { (_) -> UIImage in
                    return artworkImage
                })
                nowPlayingInfo[MPMediaItemPropertyArtwork] =  artwork
            }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    func updateNowPlayingCenter(time: Double?, playing: Bool?) {

        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()

        if let playing = playing {
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = playing ? 1.0 : 0.0
        }

        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = mediaPlayer.time.intValue / 1000
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    // Grabs a reference to the info panel view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "infoView" {
            infoTabBarViewController = segue.destination as? InfoTabBarViewController
            infoTabBarViewController?.videoPlayer = self

        }
    }

    // MARK: Player functions
    // Animate the scrubber when playing state changes
    func animateScrubber() {
        let y: CGFloat = playing ? 0 : -20
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

        self.scrubLabel.frame = CGRect(x: self.scrubberView.frame.minX - self.scrubLabel.frame.width/2, y: self.scrubLabel.frame.minY, width: self.scrubLabel.frame.width, height: self.scrubLabel.frame.height)
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

        infoTabBarViewController?.view.isUserInteractionEnabled = showingInfoPanel

        if showingInfoPanel && seeking {
            scrubLabel.isHidden = true
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
                self.scrubberView.frame = CGRect(x: self.initialSeekPos, y: self.scrubberView.frame.minY, width: 2, height: self.scrubberView.frame.height)
            }) { _ in
                self.scrubLabel.frame = CGRect(x: (self.initialSeekPos - self.scrubLabel.frame.width/2), y: self.scrubLabel.frame.minY, width: self.scrubLabel.frame.width, height: self.scrubLabel.frame.height)
                self.scrubLabel.text = self.currentTimeLabel.text
            }
            seeking = false

        }

        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut) { [self] in
            let size = infoPanelContainerView.frame.size
            let y: CGFloat = showingInfoPanel ? 87 : -size.height

            infoPanelContainerView.frame = CGRect(x: 88, y: y, width: size.width, height: size.height)
        }

    }

    // MARK: Gestures
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for item in presses {
            if item.type == .select {
                selectButtonTapped()
            }
        }
    }

    func setupGestures() {
        self.becomeFirstResponder()

        // vlc crap
        videoContentView.gestureRecognizers?.forEach { gr in
            videoContentView.removeGestureRecognizer(gr)
        }
        videoContentView.subviews.forEach { sv in
            sv.gestureRecognizers?.forEach { gr in
                sv.removeGestureRecognizer(gr)
            }
        }

        let playPauseGesture = UITapGestureRecognizer(target: self, action: #selector(self.selectButtonTapped))
        let playPauseType = UIPress.PressType.playPause
        playPauseGesture.allowedPressTypes = [NSNumber(value: playPauseType.rawValue)]
        view.addGestureRecognizer(playPauseGesture)

        let backTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.backButtonPressed(tap:)))
        let backPress = UIPress.PressType.menu
        backTapGesture.allowedPressTypes = [NSNumber(value: backPress.rawValue)]
        view.addGestureRecognizer(backTapGesture)

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.userPanned(panGestureRecognizer:)))
        view.addGestureRecognizer(panGestureRecognizer)
    }

    @objc func backButtonPressed(tap: UITapGestureRecognizer) {
        // Dismiss info panel
        if showingInfoPanel {
            if focusedOnTabBar {
                toggleInfoContainer()
            }
            return
        }

        // Cancel seek and move back to initial position
        if seeking {
            scrubLabel.isHidden = true
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
                self.scrubberView.frame = CGRect(x: self.initialSeekPos, y: 0, width: 2, height: 10)
            })
            play()
            seeking = false
        } else {
            // Dismiss view
            self.resignFirstResponder()
            mediaPlayer.stop()
            sendStopReport()
            backAction()
        }
    }

    @objc func userPanned(panGestureRecognizer: UIPanGestureRecognizer) {
        if loading {
            return
        }

        let translation = panGestureRecognizer.translation(in: view)
        let velocity = panGestureRecognizer.velocity(in: view)

        // Swiped up - Handle dismissing info panel
        if translation.y < -200 && (focusedOnTabBar && showingInfoPanel) {
            toggleInfoContainer()
            return
        }

        if showingInfoPanel {
            return
        }

        // Swiped down - Show the info panel
        if translation.y > 200 {
            toggleInfoContainer()
            return
        }

        // Ignore seek if video is playing
        if playing {
            return
        }

        // Save current position if seek is cancelled and show the scrubLabel
        if !seeking {
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

    /// Play/Pause or Select is pressed on the AppleTV remote
    @objc func selectButtonTapped() {
        print("select")
        if loading {
            return
        }

        showingControls = true
        controlsView.isHidden = false
        controlsAppearTime = CACurrentMediaTime()

        // Move to seeked position
        if seeking {
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
        updateNowPlayingCenter(time: nil, playing: mediaPlayer.state == .playing)

        if (eventName == "timeupdate" && mediaPlayer.state == .playing) || eventName != "timeupdate" {
            var ticks: Int64 = Int64(mediaPlayer.position * Float(manifest.runTimeTicks ?? 0))
            if ticks == 0 {
                ticks = manifest.userData?.playbackPositionTicks ?? 0
            }

            let progressInfo = PlaybackProgressInfo(canSeek: true, item: manifest, itemId: manifest.id, sessionId: playSessionId, mediaSourceId: manifest.id, audioStreamIndex: Int(selectedAudioTrack), subtitleStreamIndex: Int(selectedCaptionTrack), isPaused: (!playing), isMuted: false, positionTicks: ticks, playbackStartTimeTicks: Int64(startTime), volumeLevel: 100, brightness: 100, aspectRatio: nil, playMethod: playbackItem.videoType, liveStreamId: nil, playSessionId: playSessionId, repeatMode: .repeatNone, nowPlayingQueue: [], playlistItemId: "playlistItem0")

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
        let stopInfo = PlaybackStopInfo(item: manifest, itemId: manifest.id, sessionId: playSessionId, mediaSourceId: manifest.id, positionTicks: Int64(mediaPlayer.position * Float(manifest.runTimeTicks ?? 0)), liveStreamId: nil, playSessionId: playSessionId, failed: nil, nextMediaType: nil, playlistItemId: "playlistItem0", nowPlayingQueue: [])

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
        infoTabBarViewController?.setupInfoViews(mediaItem: manifest, subtitleTracks: subtitleTrackArray, selectedSubtitleTrack: selectedCaptionTrack, audioTracks: audioTrackArray, selectedAudioTrack: selectedAudioTrack, delegate: self)
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
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
