/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Combine
import Defaults
import GoogleCast
import JellyfinAPI
import MediaPlayer
import MobileVLCKit
import Stinsen
import SwiftUI
import SwiftyJSON

enum PlayerDestination {
    case remote
    case local
}

protocol PlayerViewControllerDelegate: AnyObject {
    func hideLoadingView(_ viewController: PlayerViewController)
    func showLoadingView(_ viewController: PlayerViewController)
    func exitPlayer(_ viewController: PlayerViewController)
}

class PlayerViewController: UIViewController, GCKDiscoveryManagerListener, GCKRemoteMediaClientListener {
    @RouterObject
    var main: MainCoordinator.Router?

    weak var delegate: PlayerViewControllerDelegate?

    var cancellables = Set<AnyCancellable>()
    var mediaPlayer = VLCMediaPlayer()

    @IBOutlet weak var upNextView: UIView!
    @IBOutlet weak var timeText: UILabel!
    @IBOutlet weak var timeLeftText: UILabel!
    @IBOutlet weak var videoContentView: UIView!
    @IBOutlet weak var videoControlsView: UIView!
    @IBOutlet weak var seekSlider: UISlider!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var jumpBackButton: UIButton!
    @IBOutlet weak var jumpForwardButton: UIButton!
    @IBOutlet weak var playerSettingsButton: UIButton!
    @IBOutlet weak var castButton: UIButton!

    var shouldShowLoadingScreen: Bool = false
    var ssTargetValueOffset: Int = 0
    var ssStartValue: Int = 0
    var optionsVC: VideoPlayerSettingsView?
    var castDeviceVC: VideoPlayerCastDeviceSelectorView?

    var paused: Bool = true
    var lastTime: Float = 0.0
    var startTime: Int = 0
    var controlsAppearTime: Double = 0
    var isSeeking: Bool = false

    var playerDestination: PlayerDestination = .local
    var discoveredCastDevices: [GCKDevice] = []
    var selectedCastDevice: GCKDevice?
    var jellyfinCastChannel: GCKGenericChannel?
    var remotePositionTicks: Int = 0
    private var castDiscoveryManager: GCKDiscoveryManager {
        return GCKCastContext.sharedInstance().discoveryManager
    }

    private var castSessionManager: GCKSessionManager {
        return GCKCastContext.sharedInstance().sessionManager
    }

    var hasSentRemoteSeek: Bool = false

    var selectedPlaybackSpeedIndex: Int = 3
    var selectedAudioTrack: Int32 = -1
    var selectedCaptionTrack: Int32 = -1
    var playSessionId: String = ""
    var lastProgressReportTime: Double = 0
    var subtitleTrackArray: [Subtitle] = []
    var audioTrackArray: [AudioTrack] = []
    let playbackSpeeds: [Float] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
    var jumpForwardLength: VideoPlayerJumpLength {
        return Defaults[.videoPlayerJumpForward]
    }

    var jumpBackwardLength: VideoPlayerJumpLength {
        return Defaults[.videoPlayerJumpBackward]
    }

    var manifest = BaseItemDto()
    var playbackItem = PlaybackItem()
    var remoteTimeUpdateTimer: Timer?
    var upNextViewModel = UpNextViewModel()
    var lastOri: UIInterfaceOrientation?

    // MARK: IBActions

    @IBAction func seekSliderStart(_ sender: Any) {
        if playerDestination == .local {
            sendProgressReport(eventName: "pause")
            mediaPlayer.pause()
        } else {
            isSeeking = true
        }
    }

    @IBAction func seekSliderValueChanged(_ sender: Any) {
        let videoDuration = Double(manifest.runTimeTicks! / Int64(10_000_000))
        let secondsScrubbedTo = round(Double(seekSlider.value) * videoDuration)
        let secondsScrubbedRemaining = videoDuration - secondsScrubbedTo

        timeText.text = calculateTimeText(from: secondsScrubbedTo)
        timeLeftText.text = calculateTimeText(from: secondsScrubbedRemaining)
    }

    private func calculateTimeText(from duration: Double) -> String {
        let hours = floor(duration / 3600)
        let minutes = duration.truncatingRemainder(dividingBy: 3600) / 60
        let seconds = duration.truncatingRemainder(dividingBy: 3600).truncatingRemainder(dividingBy: 60)

        let timeText: String

        if hours != 0 {
            timeText =
                "\(Int(hours)):\(String(Int(floor(minutes))).leftPad(toWidth: 2, withString: "0")):\(String(Int(floor(seconds))).leftPad(toWidth: 2, withString: "0"))"
        } else {
            timeText =
                "\(String(Int(floor(minutes))).leftPad(toWidth: 2, withString: "0")):\(String(Int(floor(seconds))).leftPad(toWidth: 2, withString: "0"))"
        }

        return timeText
    }

    @IBAction func seekSliderEnd(_ sender: Any) {
        isSeeking = false
        let videoPosition = playerDestination == .local ? Double(mediaPlayer.time.intValue / 1000) :
            Double(remotePositionTicks / Int(10_000_000))
        let videoDuration = Double(manifest.runTimeTicks! / Int64(10_000_000))
        // Scrub is value from 0..1 - find position in video and add / or remove.
        let secondsScrubbedTo = round(Double(seekSlider.value) * videoDuration)
        let offset = secondsScrubbedTo - videoPosition

        if playerDestination == .local {
            if offset > 0 {
                mediaPlayer.jumpForward(Int32(offset))
            } else {
                mediaPlayer.jumpBackward(Int32(abs(offset)))
            }
            mediaPlayer.play()
            sendProgressReport(eventName: "unpause")
        } else {
            sendJellyfinCommand(command: "Seek", options: [
                "position": Int(secondsScrubbedTo),
            ])
        }
    }

    @IBAction func exitButtonPressed(_ sender: Any) {
        sendStopReport()
        mediaPlayer.stop()

        if castSessionManager.hasConnectedCastSession() {
            castSessionManager.endSessionAndStopCasting(true)
        }

        delegate?.exitPlayer(self)
    }

    @IBAction func controlViewTapped(_ sender: Any) {
        if playerDestination == .local {
            videoControlsView.isHidden = true
            if manifest.type == "Episode" {
                smallNextUpView()
            }
        }
    }

    @IBAction func contentViewTapped(_ sender: Any) {
        if playerDestination == .local {
            videoControlsView.isHidden = false
            controlsAppearTime = CACurrentMediaTime()
        }
    }

    @IBAction func jumpBackTapped(_ sender: Any) {
        if paused == false {
            if playerDestination == .local {
                mediaPlayer.jumpBackward(jumpBackwardLength.rawValue)
            } else {
                sendJellyfinCommand(command: "Seek",
                                    options: ["position": (remotePositionTicks / 10_000_000) - Int(jumpBackwardLength.rawValue)])
            }
        }
    }

    @IBAction func jumpForwardTapped(_ sender: Any) {
        if paused == false {
            if playerDestination == .local {
                mediaPlayer.jumpForward(jumpForwardLength.rawValue)
            } else {
                sendJellyfinCommand(command: "Seek",
                                    options: ["position": (remotePositionTicks / 10_000_000) + Int(jumpForwardLength.rawValue)])
            }
        }
    }

    @IBOutlet weak var mainActionButton: UIButton!
    @IBAction func mainActionButtonPressed(_ sender: Any) {
        if paused {
            if playerDestination == .local {
                mediaPlayer.play()
                mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
                paused = false
            } else {
                sendJellyfinCommand(command: "Unpause", options: [:])
                mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
                paused = false
            }
        } else {
            if playerDestination == .local {
                mediaPlayer.pause()
                mainActionButton.setImage(UIImage(systemName: "play"), for: .normal)
                paused = true
            } else {
                sendJellyfinCommand(command: "Pause", options: [:])
                mainActionButton.setImage(UIImage(systemName: "play"), for: .normal)
                paused = true
            }
        }
    }

    @IBAction func settingsButtonTapped(_ sender: UIButton) {
        optionsVC = VideoPlayerSettingsView()
        optionsVC?.playerDelegate = self

        optionsVC?.modalPresentationStyle = .popover
        optionsVC?.popoverPresentationController?.sourceView = playerSettingsButton

        // Present the view controller (in a popover).
        present(optionsVC!, animated: true) {
            print("popover visible, pause playback")
            self.mediaPlayer.pause()
            self.mainActionButton.setImage(UIImage(systemName: "play"), for: .normal)
        }
    }

    // MARK: Cast methods

    @IBAction func castButtonPressed(_ sender: Any) {
        if selectedCastDevice == nil {
            LogManager.shared.log.debug("Presenting Cast modal")
            castDeviceVC = VideoPlayerCastDeviceSelectorView()
            castDeviceVC?.delegate = self

            castDeviceVC?.modalPresentationStyle = .popover
            castDeviceVC?.popoverPresentationController?.sourceView = castButton

            // Present the view controller (in a popover).
            present(castDeviceVC!, animated: true) {
                self.mediaPlayer.pause()
                self.mainActionButton.setImage(UIImage(systemName: "play"), for: .normal)
            }
        } else {
            LogManager.shared.log.info("Stopping casting session: button was pressed.")
            castSessionManager.endSessionAndStopCasting(true)
            selectedCastDevice = nil
            castButton.isEnabled = true
            castButton.setImage(UIImage(named: "CastDisconnected"), for: .normal)
            playerDestination = .local
        }
    }

    func castPopoverDismissed() {
        LogManager.shared.log.debug("Cast modal dismissed")
        castDeviceVC?.dismiss(animated: true, completion: nil)
        if playerDestination == .local {
            mediaPlayer.play()
        }
        mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
    }

    func castDeviceChanged() {
        LogManager.shared.log.debug("Cast device changed")
        if selectedCastDevice != nil {
            LogManager.shared.log.debug("New device: \(selectedCastDevice?.friendlyName ?? "UNKNOWN")")
            playerDestination = .remote
            castSessionManager.add(self)
            castSessionManager.startSession(with: selectedCastDevice!)
        }
    }

    // MARK: Cast End

    func settingsPopoverDismissed() {
        optionsVC?.dismiss(animated: true, completion: nil)
        if playerDestination == .local {
            mediaPlayer.play()
            mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
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
            if self.playerDestination == .local {
                self.mediaPlayer.pause()
                self.sendProgressReport(eventName: "pause")
            } else {
                self.sendJellyfinCommand(command: "Pause", options: [:])
            }
            self.mainActionButton.setImage(UIImage(systemName: "play"), for: .normal)
            return .success
        }

        // Add handler for Play command
        commandCenter.playCommand.addTarget { _ in
            if self.playerDestination == .local {
                self.mediaPlayer.play()
                self.sendProgressReport(eventName: "unpause")
            } else {
                self.sendJellyfinCommand(command: "Unpause", options: [:])
            }
            self.mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
            return .success
        }

        // Add handler for FF command
        commandCenter.seekForwardCommand.addTarget { _ in
            if self.playerDestination == .local {
                self.mediaPlayer.jumpForward(30)
                self.sendProgressReport(eventName: "timeupdate")
            } else {
                self.sendJellyfinCommand(command: "Seek", options: ["position": (self.remotePositionTicks / 10_000_000) + 30])
            }
            return .success
        }

        // Add handler for RW command
        commandCenter.seekBackwardCommand.addTarget { _ in
            if self.playerDestination == .local {
                self.mediaPlayer.jumpBackward(15)
                self.sendProgressReport(eventName: "timeupdate")
            } else {
                self.sendJellyfinCommand(command: "Seek", options: ["position": (self.remotePositionTicks / 10_000_000) - 15])
            }
            return .success
        }

        // Scrubber
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] (remoteEvent) -> MPRemoteCommandHandlerStatus in
            guard let self = self else { return .commandFailed }

            if let event = remoteEvent as? MPChangePlaybackPositionCommandEvent {
                let targetSeconds = event.positionTime

                let videoPosition = Double(self.mediaPlayer.time.intValue)
                let offset = targetSeconds - videoPosition

                if self.playerDestination == .local {
                    if offset > 0 {
                        self.mediaPlayer.jumpForward(Int32(offset) / 1000)
                    } else {
                        self.mediaPlayer.jumpBackward(Int32(abs(offset)) / 1000)
                    }
                    self.sendProgressReport(eventName: "unpause")
                } else {}

                return .success
            } else {
                return .commandFailed
            }
        }

        var nowPlayingInfo = [String: Any]()

        var runTicks = 0
        var playbackTicks = 0

        if let ticks = manifest.runTimeTicks {
            runTicks = Int(ticks / 10_000_000)
        }

        if let ticks = manifest.userData?.playbackPositionTicks {
            playbackTicks = Int(ticks / 10_000_000)
        }

        nowPlayingInfo[MPMediaItemPropertyTitle] = manifest.name ?? "Jellyfin Video"
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = AVMediaType.video
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = runTicks
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = playbackTicks

        if let imageData = NSData(contentsOf: manifest.getPrimaryImage(maxWidth: 200)) {
            if let artworkImage = UIImage(data: imageData as Data) {
                let artwork = MPMediaItemArtwork(boundsSize: artworkImage.size, requestHandler: { (_) -> UIImage in
                    artworkImage
                })
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    // MARK: viewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()
        if manifest.type == "Movie" {
            titleLabel.text = manifest.name ?? ""
        } else {
            titleLabel.text = "\(L10n.seasonAndEpisode(String(manifest.parentIndexNumber ?? 0), String(manifest.indexNumber ?? 0))) “\(manifest.name ?? "")”"

            setupNextUpView()
            upNextViewModel.delegate = self
        }

        DispatchQueue.main.async {
            self.lastOri = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? nil
            AppDelegate.orientationLock = .landscape

            if self.lastOri != nil {
                if !self.lastOri!.isLandscape {
                    UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                    UIViewController.attemptRotationToDeviceOrientation()
                }
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(didChangedOrientation),
                                               name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    @objc func didChangedOrientation() {
        lastOri = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
    }

    func mediaHasStartedPlaying() {
        castButton.isHidden = true
        let discoveryCriteria = GCKDiscoveryCriteria(applicationID: "F007D354")
        let gckCastOptions = GCKCastOptions(discoveryCriteria: discoveryCriteria)
        GCKCastContext.setSharedInstanceWith(gckCastOptions)
        castDiscoveryManager.passiveScan = true
        castDiscoveryManager.add(self)
        castDiscoveryManager.startDiscovery()
    }

    func didUpdateDeviceList() {
        let totalDevices = castDiscoveryManager.deviceCount
        discoveredCastDevices = []
        if totalDevices > 0 {
            for i in 0 ... totalDevices - 1 {
                let device = castDiscoveryManager.device(at: i)
                discoveredCastDevices.append(device)
            }
        }

        if !discoveredCastDevices.isEmpty {
            castButton.isHidden = false
            castButton.isEnabled = true
            castButton.setImage(UIImage(named: "CastDisconnected"), for: .normal)
        } else {
            castButton.isHidden = true
            castButton.isEnabled = false
            castButton.setImage(nil, for: .normal)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        navigationController?.isNavigationBarHidden = false
        overrideUserInterfaceStyle = .unspecified
        DispatchQueue.main.async {
            if self.lastOri != nil {
                AppDelegate.orientationLock = .all
                UIDevice.current.setValue(self.lastOri!.rawValue, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }

    // MARK: viewDidAppear

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        overrideUserInterfaceStyle = .dark
        tabBarController?.tabBar.isHidden = true
        navigationController?.isNavigationBarHidden = true

        mediaPlayer.perform(Selector(("setTextRendererFontSize:")), with: 14)
        // mediaPlayer.wrappedValue.perform(Selector(("setTextRendererFont:")), with: "Copperplate")

        mediaPlayer.delegate = self
        mediaPlayer.drawable = videoContentView

        setupMediaPlayer()
        setupJumpLengthButtons()
    }

    func setupMediaPlayer() {
        // Fetch max bitrate from UserDefaults depending on current connection mode
        let maxBitrate = Defaults[.inNetworkBandwidth]
        print(maxBitrate)
        // Build a device profile
        let builder = DeviceProfileBuilder()
        builder.setMaxBitrate(bitrate: maxBitrate)
        let profile = builder.buildProfile()
        let playbackInfo = PlaybackInfoDto(userId: SessionManager.main.currentLogin.user.id, maxStreamingBitrate: Int(maxBitrate),
                                           startTimeTicks: manifest.userData?.playbackPositionTicks ?? 0, deviceProfile: profile,
                                           autoOpenLiveStream: true)

        DispatchQueue.global(qos: .userInitiated).async { [self] in
            delegate?.showLoadingView(self)
            MediaInfoAPI.getPostedPlaybackInfo(itemId: manifest.id!, userId: SessionManager.main.currentLogin.user.id,
                                               maxStreamingBitrate: Int(maxBitrate),
                                               startTimeTicks: manifest.userData?.playbackPositionTicks ?? 0, autoOpenLiveStream: true,
                                               playbackInfoDto: playbackInfo)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case let .failure(error):
                        if let err = error as? ErrorResponse {
                            switch err {
                            case .error(401, _, _, _):
                                self.delegate?.exitPlayer(self)
                                SessionManager.main.logout()
                            case .error:
                                self.delegate?.exitPlayer(self)
                            }
                        }
                    }
                }, receiveValue: { [self] response in
                    dump(response)
                    playSessionId = response.playSessionId ?? ""
                    let mediaSource = response.mediaSources!.first.self!
                    if mediaSource.transcodingUrl != nil {
                        // Item is being transcoded by request of server
                        let streamURL = URL(string: "\(SessionManager.main.currentLogin.server.uri)\(mediaSource.transcodingUrl!)")
                        let item = PlaybackItem()
                        item.videoType = .transcode
                        item.videoUrl = streamURL!

                        let disableSubtitleTrack = Subtitle(name: "Disabled", id: -1, url: nil, delivery: .embed, codec: "",
                                                            languageCode: "")
                        subtitleTrackArray.append(disableSubtitleTrack)

                        // Loop through media streams and add to array
                        for stream in mediaSource.mediaStreams ?? [] {
                            if stream.type == .subtitle {
                                var deliveryUrl: URL?
                                if stream.deliveryMethod == .external {
                                    deliveryUrl = URL(string: "\(SessionManager.main.currentLogin.server.uri)\(stream.deliveryUrl ?? "")")!
                                } else {
                                    deliveryUrl = nil
                                }
                                let subtitle = Subtitle(name: stream.displayTitle ?? "Unknown", id: Int32(stream.index!), url: deliveryUrl,
                                                        delivery: stream.deliveryMethod!, codec: stream.codec ?? "webvtt",
                                                        languageCode: stream.language ?? "")

                                if subtitle.delivery != .encode {
                                    subtitleTrackArray.append(subtitle)
                                }
                            }

                            if stream.type == .audio {
                                let subtitle = AudioTrack(name: stream.displayTitle!, languageCode: stream.language ?? "",
                                                          id: Int32(stream.index!))
                                if stream.isDefault! == true {
                                    selectedAudioTrack = Int32(stream.index!)
                                }
                                audioTrackArray.append(subtitle)
                            }
                        }

                        if selectedAudioTrack == -1 {
                            if !audioTrackArray.isEmpty {
                                selectedAudioTrack = audioTrackArray[0].id
                            }
                        }

                        self.sendPlayReport()
                        playbackItem = item
                    } else {
                        // TODO: todo
                        // Item will be directly played by the client.
                        let streamURL = URL(string: "\(SessionManager.main.currentLogin.server.uri)/Videos/\(manifest.id!)/stream?Static=true&mediaSourceId=\(manifest.id!)&Tag=\(mediaSource.eTag ?? "")")!
//                            URL(string: "\(SessionManager.main.currentLogin.server.uri)/Videos/\(manifest.id!)/stream?Static=true&mediaSourceId=\(manifest.id!)&deviceId=\(SessionManager.current.deviceID)&api_key=\(SessionManager.current.accessToken)&Tag=\(mediaSource.eTag ?? "")")!

                        let item = PlaybackItem()
                        item.videoUrl = streamURL
                        item.videoType = .directPlay

                        let disableSubtitleTrack = Subtitle(name: "Disabled", id: -1, url: nil, delivery: .embed, codec: "",
                                                            languageCode: "")
                        subtitleTrackArray.append(disableSubtitleTrack)

                        // Loop through media streams and add to array
                        for stream in mediaSource.mediaStreams ?? [] {
                            if stream.type == .subtitle {
                                var deliveryUrl: URL?
                                if stream.deliveryMethod == .external {
                                    deliveryUrl = URL(string: "\(SessionManager.main.currentLogin.server.uri)\(stream.deliveryUrl!)")!
                                } else {
                                    deliveryUrl = nil
                                }
                                let subtitle = Subtitle(name: stream.displayTitle ?? "Unknown", id: Int32(stream.index!), url: deliveryUrl,
                                                        delivery: stream.deliveryMethod!, codec: stream.codec!,
                                                        languageCode: stream.language ?? "")

                                if subtitle.delivery != .encode {
                                    subtitleTrackArray.append(subtitle)
                                }
                            }

                            if stream.type == .audio {
                                let subtitle = AudioTrack(name: stream.displayTitle!, languageCode: stream.language ?? "",
                                                          id: Int32(stream.index!))
                                if stream.isDefault! == true {
                                    selectedAudioTrack = Int32(stream.index!)
                                }
                                audioTrackArray.append(subtitle)
                            }
                        }

                        if selectedAudioTrack == -1 {
                            if !audioTrackArray.isEmpty {
                                selectedAudioTrack = audioTrackArray[0].id
                            }
                        }

                        self.sendPlayReport()
                        playbackItem = item

                        // self.setupNowPlayingCC()
                    }

                    startLocalPlaybackEngine(true)
                })
                .store(in: &cancellables)
        }
    }

    private func setupJumpLengthButtons() {
        let buttonFont = UIFont.systemFont(ofSize: 35, weight: .regular)
        jumpForwardButton.setImage(jumpForwardLength.generateForwardImage(with: buttonFont), for: .normal)
        jumpBackButton.setImage(jumpBackwardLength.generateBackwardImage(with: buttonFont), for: .normal)
    }

    func setupTracksForPreferredDefaults() {
        subtitleTrackArray.forEach { subtitle in
            if Defaults[.isAutoSelectSubtitles] {
                if Defaults[.autoSelectSubtitlesLangCode] == "Auto",
                   subtitle.languageCode.contains(Locale.current.languageCode ?? "")
                {
                    selectedCaptionTrack = subtitle.id
                    mediaPlayer.currentVideoSubTitleIndex = subtitle.id
                } else if subtitle.languageCode.contains(Defaults[.autoSelectSubtitlesLangCode]) {
                    selectedCaptionTrack = subtitle.id
                    mediaPlayer.currentVideoSubTitleIndex = subtitle.id
                }
            }
        }

        audioTrackArray.forEach { audio in
            if audio.languageCode.contains(Defaults[.autoSelectAudioLangCode]) {
                selectedAudioTrack = audio.id
                mediaPlayer.currentAudioTrackIndex = audio.id
            }
        }
    }

    func startLocalPlaybackEngine(_ fetchCaptions: Bool) {
        mediaPlayer.media = VLCMedia(url: playbackItem.videoUrl)
        mediaPlayer.play()
        sendPlayReport()

        // 1 second = 10,000,000 ticks
        var startTicks: Int64 = 0
        if remotePositionTicks == 0 {
            startTicks = manifest.userData?.playbackPositionTicks ?? 0
        } else {
            startTicks = Int64(remotePositionTicks)
        }

        if startTicks != 0 {
            let videoPosition = Double(mediaPlayer.time.intValue / 1000)
            let secondsScrubbedTo = startTicks / 10_000_000
            let offset = secondsScrubbedTo - Int64(videoPosition)
            if offset > 0 {
                mediaPlayer.jumpForward(Int32(offset))
            } else {
                mediaPlayer.jumpBackward(Int32(abs(offset)))
            }
        }

        if fetchCaptions {
            mediaPlayer.pause()
            subtitleTrackArray.forEach { sub in
                // stupid fxcking jeff decides to re-encode these when added.
                // only add playback streams when codec not supported by VLC.
                if sub.id != -1, sub.delivery == .external, sub.codec != "subrip" {
                    mediaPlayer.addPlaybackSlave(sub.url!, type: .subtitle, enforce: false)
                }
            }
        }

        mediaHasStartedPlaying()
        delegate?.hideLoadingView(self)

        videoContentView.setNeedsLayout()
        videoContentView.setNeedsDisplay()
        view.setNeedsLayout()
        view.setNeedsDisplay()
        videoControlsView.setNeedsLayout()
        videoControlsView.setNeedsDisplay()

        mediaPlayer.pause()
        mediaPlayer.play()
        setupTracksForPreferredDefaults()
    }

    // MARK: VideoPlayerSettings Delegate

    func subtitleTrackChanged(newTrackID: Int32) {
        selectedCaptionTrack = newTrackID
        mediaPlayer.currentVideoSubTitleIndex = newTrackID
    }

    func audioTrackChanged(newTrackID: Int32) {
        selectedAudioTrack = newTrackID
        mediaPlayer.currentAudioTrackIndex = newTrackID
    }

    func playbackSpeedChanged(index: Int) {
        selectedPlaybackSpeedIndex = index
        mediaPlayer.rate = playbackSpeeds[index]
    }

    func smallNextUpView() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) { [self] in
            upNextViewModel.largeView = false
        }
    }

    func setupNextUpView() {
        getNextEpisode()

        // Create the swiftUI view
        let contentView = UIHostingController(rootView: VideoUpNextView(viewModel: upNextViewModel))
        upNextView.addSubview(contentView.view)
        contentView.view.backgroundColor = .clear
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.view.topAnchor.constraint(equalTo: upNextView.topAnchor).isActive = true
        contentView.view.bottomAnchor.constraint(equalTo: upNextView.bottomAnchor).isActive = true
        contentView.view.leftAnchor.constraint(equalTo: upNextView.leftAnchor).isActive = true
        contentView.view.rightAnchor.constraint(equalTo: upNextView.rightAnchor).isActive = true
    }

    func getNextEpisode() {
        TvShowsAPI.getEpisodes(seriesId: manifest.seriesId!, userId: SessionManager.main.currentLogin.user.id, startItemId: manifest.id,
                               limit: 2)
            .sink(receiveCompletion: { completion in
                print(completion)
            }, receiveValue: { [self] response in
                // Returns 2 items, the first is the current episode
                // The second is the next episode
                if let item = response.items?.last {
                    self.upNextViewModel.item = item
                }
            })
            .store(in: &cancellables)
    }

    func setPlayerToNextUp() {
        mediaPlayer.stop()

        ssTargetValueOffset = 0
        ssStartValue = 0

        paused = true
        lastTime = 0.0
        startTime = 0
        controlsAppearTime = 0
        isSeeking = false

        remotePositionTicks = 0

        selectedPlaybackSpeedIndex = 3
        selectedAudioTrack = -1
        selectedCaptionTrack = -1
        playSessionId = ""
        lastProgressReportTime = 0
        subtitleTrackArray = []
        audioTrackArray = []

        manifest = upNextViewModel.item!
        playbackItem = PlaybackItem()

        upNextViewModel.item = nil

        upNextView.isHidden = true
        shouldShowLoadingScreen = true
        videoControlsView.isHidden = true

        titleLabel.text = "\(L10n.seasonAndEpisode(String(manifest.parentIndexNumber ?? 0), String(manifest.indexNumber ?? 0))) “\(manifest.name ?? "")”"

        setupMediaPlayer()
        getNextEpisode()
    }
}

// MARK: - GCKGenericChannelDelegate

extension PlayerViewController: GCKGenericChannelDelegate {
    @objc func updateRemoteTime() {
        castButton.setImage(UIImage(named: "CastConnected"), for: .normal)
        if !paused {
            remotePositionTicks = remotePositionTicks + 2_000_000 // add 0.2 secs every timer evt.
        }

        if isSeeking == false {
            let positiveSeconds = Double(remotePositionTicks / 10_000_000)
            let remainingSeconds = Double((manifest.runTimeTicks! - Int64(remotePositionTicks)) / 10_000_000)

            timeText.text = calculateTimeText(from: positiveSeconds)
            timeLeftText.text = calculateTimeText(from: remainingSeconds)

            let playbackProgress = Float(remotePositionTicks) / Float(manifest.runTimeTicks!)
            seekSlider.setValue(playbackProgress, animated: true)
        }
    }

    func cast(_ channel: GCKGenericChannel, didReceiveTextMessage message: String, withNamespace protocolNamespace: String) {
        if let data = message.data(using: .utf8) {
            if let json = try? JSON(data: data) {
                let messageType = json["type"].string ?? ""
                if messageType == "playbackprogress" {
                    dump(json)
                    if remotePositionTicks > 100 {
                        if hasSentRemoteSeek == false {
                            hasSentRemoteSeek = true
                            sendJellyfinCommand(command: "Seek", options: [
                                "position": Int(Float(manifest.runTimeTicks! / 10_000_000) * mediaPlayer.position),
                            ])
                        }
                    }
                    paused = json["data"]["PlayState"]["IsPaused"].boolValue
                    remotePositionTicks = json["data"]["PlayState"]["PositionTicks"].int ?? 0
                    if remoteTimeUpdateTimer == nil {
                        remoteTimeUpdateTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(updateRemoteTime),
                                                                     userInfo: nil, repeats: true)
                    }
                }
            }
        }
    }

    func sendJellyfinCommand(command: String, options: [String: Any]) {
        let payload: [String: Any] = [
            "options": options,
            "command": command,
            "userId": SessionManager.main.currentLogin.user.id,
//            "deviceId": SessionManager.main.currentLogin.de.deviceID,
            "accessToken": SessionManager.main.currentLogin.user.accessToken,
            "serverAddress": SessionManager.main.currentLogin.server.uri,
            "serverId": SessionManager.main.currentLogin.server.id,
            "serverVersion": "10.8.0",
            "receiverName": castSessionManager.currentCastSession!.device.friendlyName!,
            "subtitleBurnIn": false,
        ]
        let jsonData = JSON(payload)

        jellyfinCastChannel?.sendTextMessage(jsonData.rawString()!, error: nil)

        if command == "Seek" {
            remotePositionTicks = remotePositionTicks + ((options["position"] as! Int) * 10_000_000)
            // Send playback report as Jellyfin Chromecast isn't smarter than a rock.
            let progressInfo = PlaybackProgressInfo(canSeek: true, item: manifest, itemId: manifest.id, sessionId: playSessionId,
                                                    mediaSourceId: manifest.id, audioStreamIndex: Int(selectedAudioTrack),
                                                    subtitleStreamIndex: Int(selectedCaptionTrack), isPaused: paused, isMuted: false,
                                                    positionTicks: Int64(remotePositionTicks), playbackStartTimeTicks: Int64(startTime),
                                                    volumeLevel: 100, brightness: 100, aspectRatio: nil, playMethod: playbackItem.videoType,
                                                    liveStreamId: nil, playSessionId: playSessionId, repeatMode: .repeatNone,
                                                    nowPlayingQueue: [], playlistItemId: "playlistItem0")

            PlaystateAPI.reportPlaybackProgress(playbackProgressInfo: progressInfo)
                .sink(receiveCompletion: { result in
                    print(result)
                }, receiveValue: { _ in
                    print("Playback progress report sent!")
                })
                .store(in: &cancellables)
        }
    }
}

// MARK: - GCKSessionManagerListener

extension PlayerViewController: GCKSessionManagerListener {
    func sessionDidStart(manager: GCKSessionManager, didStart session: GCKCastSession) {
        sendStopReport()
        mediaPlayer.stop()

        playerDestination = .remote
        videoContentView.isHidden = true
        videoControlsView.isHidden = false
        castButton.setImage(UIImage(named: "CastConnected"), for: .normal)
        manager.currentCastSession?.start()

        jellyfinCastChannel!.delegate = self
        session.add(jellyfinCastChannel!)

        if let client = session.remoteMediaClient {
            client.add(self)
        }

        let playNowOptions: [String: Any] = [
            "items": [[
                "Id": manifest.id!,
                "ServerId": SessionManager.main.currentLogin.server.id,
                "Name": manifest.name!,
                "Type": manifest.type!,
                "MediaType": manifest.mediaType!,
                "IsFolder": manifest.isFolder!,
            ]],
        ]
        sendJellyfinCommand(command: "PlayNow", options: playNowOptions)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKCastSession) {
        jellyfinCastChannel = GCKGenericChannel(namespace: "urn:x-cast:com.connectsdk")
        sessionDidStart(manager: sessionManager, didStart: session)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
        jellyfinCastChannel = GCKGenericChannel(namespace: "urn:x-cast:com.connectsdk")
        sessionDidStart(manager: sessionManager, didStart: session)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKCastSession, withError error: Error) {
        LogManager.shared.log.error((error as NSError).debugDescription)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKCastSession, withError error: Error?) {
        if error != nil {
            LogManager.shared.log.error((error! as NSError).debugDescription)
        }

        playerDestination = .local
        videoContentView.isHidden = false
        remoteTimeUpdateTimer?.invalidate()
        castButton.setImage(UIImage(named: "CastDisconnected"), for: .normal)
        startLocalPlaybackEngine(false)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didSuspend session: GCKCastSession, with reason: GCKConnectionSuspendReason) {
        playerDestination = .local
        videoContentView.isHidden = false
        remoteTimeUpdateTimer?.invalidate()
        castButton.setImage(UIImage(named: "CastDisconnected"), for: .normal)
        startLocalPlaybackEngine(false)
    }
}

// MARK: - VLCMediaPlayer Delegates

extension PlayerViewController: VLCMediaPlayerDelegate {
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        let currentState: VLCMediaPlayerState = mediaPlayer.state
        switch currentState {
        case .stopped:
            LogManager.shared.log.debug("Player state changed: STOPPED")
        case .ended:
            LogManager.shared.log.debug("Player state changed: ENDED")
        case .playing:
            LogManager.shared.log.debug("Player state changed: PLAYING")
            sendProgressReport(eventName: "unpause")
            delegate?.hideLoadingView(self)
            paused = false
        case .paused:
            LogManager.shared.log.debug("Player state changed: PAUSED")
            paused = true
        case .opening:
            LogManager.shared.log.debug("Player state changed: OPENING")
        case .buffering:
            LogManager.shared.log.debug("Player state changed: BUFFERING")
            delegate?.showLoadingView(self)
        case .error:
            LogManager.shared.log.error("Video had error.")
            sendStopReport()
        case .esAdded:
            mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
        @unknown default:
            break
        }
    }

    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        let time = mediaPlayer.position
        if abs(time - lastTime) > 0.00005 {
            paused = false
            mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
            seekSlider.setValue(mediaPlayer.position, animated: true)
            delegate?.hideLoadingView(self)

            if manifest.type == "Episode", upNextViewModel.item != nil {
                if time > 0.96 {
                    upNextView.isHidden = false
                    jumpForwardButton.isHidden = true
                } else {
                    upNextView.isHidden = true
                    jumpForwardButton.isHidden = false
                }
            }

            timeText.text = mediaPlayer.time.stringValue
            timeLeftText.text = String(mediaPlayer.remainingTime.stringValue.dropFirst())

            if CACurrentMediaTime() - controlsAppearTime > 5 {
                smallNextUpView()
                UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                    self.videoControlsView.alpha = 0.0
                }, completion: { (_: Bool) in
                    self.videoControlsView.isHidden = true
                    self.videoControlsView.alpha = 1
                })
                controlsAppearTime = 999_999_999_999_999
            }
            lastTime = time
        }

        if CACurrentMediaTime() - lastProgressReportTime > 5 {
            mediaPlayer.currentVideoSubTitleIndex = selectedCaptionTrack
            sendProgressReport(eventName: "timeupdate")
            lastProgressReportTime = CACurrentMediaTime()
        }
    }
}

struct VideoPlayerView: View {
    var item: BaseItemDto
    @State private var isLoading = false

    var body: some View {
        // Loading UI needs to be moved into ViewController later
        LoadingViewNoBlur(isShowing: $isLoading) {
            VLCPlayerWithControls(item: item, loadBinding: $isLoading)
                .navigationBarHidden(true)
                .navigationBarBackButtonHidden(true)
                .statusBar(hidden: true)
                .edgesIgnoringSafeArea(.all)
                .prefersHomeIndicatorAutoHidden(true)
        }
    }
}

// MARK: End VideoPlayerVC

struct VLCPlayerWithControls: UIViewControllerRepresentable {
    var item: BaseItemDto
    @RouterObject var playerRouter: VideoPlayerCoordinator.Router?

    let loadBinding: Binding<Bool>

    class Coordinator: NSObject, PlayerViewControllerDelegate {
        var parent: VLCPlayerWithControls
        let loadBinding: Binding<Bool>

        init(parent: VLCPlayerWithControls, loadBinding: Binding<Bool>) {
            self.parent = parent
            self.loadBinding = loadBinding
        }

        func hideLoadingView(_ viewController: PlayerViewController) {
            loadBinding.wrappedValue = false
        }

        func showLoadingView(_ viewController: PlayerViewController) {
            loadBinding.wrappedValue = true
        }

        func exitPlayer(_ viewController: PlayerViewController) {
            parent.playerRouter?.dismissCoordinator()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, loadBinding: loadBinding)
    }

    typealias UIViewControllerType = PlayerViewController
    func makeUIViewController(context: UIViewControllerRepresentableContext<VLCPlayerWithControls>) -> VLCPlayerWithControls
        .UIViewControllerType
    {
        let storyboard = UIStoryboard(name: "VideoPlayer", bundle: nil)
        let customViewController = storyboard.instantiateViewController(withIdentifier: "VideoPlayer") as! PlayerViewController
        customViewController.manifest = item
        customViewController.delegate = context.coordinator
        return customViewController
    }

    func updateUIViewController(_ uiViewController: VLCPlayerWithControls.UIViewControllerType,
                                context: UIViewControllerRepresentableContext<VLCPlayerWithControls>) {}
}

// MARK: - Play State Update Methods

extension PlayerViewController {
    func sendProgressReport(eventName: String) {
        if (eventName == "timeupdate" && mediaPlayer.state == .playing) || eventName != "timeupdate" {
            var ticks = Int64(mediaPlayer.position * Float(manifest.runTimeTicks!))
            if ticks == 0 {
                ticks = manifest.userData?.playbackPositionTicks ?? 0
            }

            let progressInfo = PlaybackProgressInfo(canSeek: true, item: manifest, itemId: manifest.id, sessionId: playSessionId,
                                                    mediaSourceId: manifest.id, audioStreamIndex: Int(selectedAudioTrack),
                                                    subtitleStreamIndex: Int(selectedCaptionTrack), isPaused: mediaPlayer.state == .paused,
                                                    isMuted: false, positionTicks: ticks, playbackStartTimeTicks: Int64(startTime),
                                                    volumeLevel: 100, brightness: 100, aspectRatio: nil, playMethod: playbackItem.videoType,
                                                    liveStreamId: nil, playSessionId: playSessionId, repeatMode: .repeatNone,
                                                    nowPlayingQueue: [], playlistItemId: "playlistItem0")

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
        let stopInfo = PlaybackStopInfo(item: manifest, itemId: manifest.id, sessionId: playSessionId, mediaSourceId: manifest.id,
                                        positionTicks: Int64(mediaPlayer.position * Float(manifest.runTimeTicks!)), liveStreamId: nil,
                                        playSessionId: playSessionId, failed: nil, nextMediaType: nil, playlistItemId: "playlistItem0",
                                        nowPlayingQueue: [])

        PlaystateAPI.reportPlaybackStopped(playbackStopInfo: stopInfo)
            .sink(receiveCompletion: { result in
                print(result)
            }, receiveValue: { _ in
                print("Playback stop report sent!")
            })
            .store(in: &cancellables)
    }

    func sendPlayReport() {
        startTime = Int(Date().timeIntervalSince1970) * 10_000_000

        print("sending play report!")

        let startInfo = PlaybackStartInfo(canSeek: true, item: manifest, itemId: manifest.id, sessionId: playSessionId,
                                          mediaSourceId: manifest.id, audioStreamIndex: Int(selectedAudioTrack),
                                          subtitleStreamIndex: Int(selectedCaptionTrack), isPaused: false, isMuted: false,
                                          positionTicks: manifest.userData?.playbackPositionTicks, playbackStartTimeTicks: Int64(startTime),
                                          volumeLevel: 100, brightness: 100, aspectRatio: nil, playMethod: playbackItem.videoType,
                                          liveStreamId: nil, playSessionId: playSessionId, repeatMode: .repeatNone, nowPlayingQueue: [],
                                          playlistItemId: "playlistItem0")

        PlaystateAPI.reportPlaybackStart(playbackStartInfo: startInfo)
            .sink(receiveCompletion: { result in
                print(result)
            }, receiveValue: { _ in
                print("Playback start report sent!")
            })
            .store(in: &cancellables)
    }
}

extension UINavigationController {
    override open var childForHomeIndicatorAutoHidden: UIViewController? {
        return nil
    }
}
