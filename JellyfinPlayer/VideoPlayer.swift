/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import MobileVLCKit
import JellyfinAPI
import MediaPlayer
import Combine
import SwiftyJSON

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

enum PlayerDestination {
    case remote
    case local
}

class PlaybackItem: ObservableObject {
    @Published var videoType: PlayMethod = .directPlay
    @Published var videoUrl: URL = URL(string: "https://example.com")!
}

protocol PlayerViewControllerDelegate: AnyObject {
    func hideLoadingView(_ viewController: PlayerViewController)
    func showLoadingView(_ viewController: PlayerViewController)
    func exitPlayer(_ viewController: PlayerViewController)
}

class PlayerViewController: UIViewController, VLCMediaDelegate, VLCMediaPlayerDelegate, CastClientDelegate {

    weak var delegate: PlayerViewControllerDelegate?

    var cancellables = Set<AnyCancellable>()
    var mediaPlayer = VLCMediaPlayer()

    @IBOutlet weak var timeText: UILabel!
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
    
    var discoveredCastDevices: [CastDevice] = [] //not private due to VPCDS using it.
    var selectedCastDevice: CastDevice? //same here
    private var castClient: CastClient?
    private var playerDestination: PlayerDestination = .local;
    private var castAppTransportID: String = "";
    private var remotePlayIsPlaying: Bool = false;
    private var remotePlaySeekState: Int = 0;
    private let castScanner: CastDeviceScanner = CastDeviceScanner();

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
    var playSessionId: String = ""
    var lastProgressReportTime: Double = 0

    var subtitleTrackArray: [Subtitle] = []
    var audioTrackArray: [AudioTrack] = []

    var manifest: BaseItemDto = BaseItemDto()
    var playbackItem = PlaybackItem()

    // MARK: IBActions
    @IBAction func seekSliderStart(_ sender: Any) {
        if(playerDestination == .local) {
            sendProgressReport(eventName: "pause")
            mediaPlayer.pause()
        }
    }

    @IBAction func seekSliderValueChanged(_ sender: Any) {
        let videoDuration = Double(mediaPlayer.time.intValue + abs(mediaPlayer.remainingTime.intValue))/1000
        let secondsScrubbedTo = round(Double(seekSlider.value) * videoDuration)
        let scrubRemaining = videoDuration - secondsScrubbedTo
        let remainingTime = scrubRemaining
        let hours = floor(remainingTime / 3600)
        let minutes = (remainingTime.truncatingRemainder(dividingBy: 3600)) / 60
        let seconds = (remainingTime.truncatingRemainder(dividingBy: 3600)).truncatingRemainder(dividingBy: 60)
        if hours != 0 {
            timeText.text = "\(Int(hours)):\(String(Int(floor(minutes))).leftPad(toWidth: 2, withString: "0")):\(String(Int(floor(seconds))).leftPad(toWidth: 2, withString: "0"))"
        } else {
            timeText.text = "\(String(Int(floor(minutes))).leftPad(toWidth: 2, withString: "0")):\(String(Int(floor(seconds))).leftPad(toWidth: 2, withString: "0"))"
        }
    }

    @IBAction func seekSliderEnd(_ sender: Any) {
        print("ss end")
        let videoPosition = Double(mediaPlayer.time.intValue)
        let videoDuration = Double(mediaPlayer.time.intValue + abs(mediaPlayer.remainingTime.intValue))
        // Scrub is value from 0..1 - find position in video and add / or remove.
        let secondsScrubbedTo = round(Double(seekSlider.value) * videoDuration)
        let offset = secondsScrubbedTo - videoPosition
        
        if(playerDestination == .local) {
            mediaPlayer.play()
            if offset > 0 {
                mediaPlayer.jumpForward(Int32(offset)/1000)
            } else {
                mediaPlayer.jumpBackward(Int32(abs(offset))/1000)
            }
            sendProgressReport(eventName: "unpause")
        }
    }

    @IBAction func exitButtonPressed(_ sender: Any) {
        sendStopReport()
        mediaPlayer.stop()
        
        if(playerDestination == .remote) {
            castClient?.stopCurrentApp()
            castClient?.disconnect()
            castClient = nil
            selectedCastDevice = nil
            playerDestination = .local
        }
        
        delegate?.exitPlayer(self)
    }

    @IBAction func controlViewTapped(_ sender: Any) {
        if(playerDestination == .local) {
            videoControlsView.isHidden = true
        }
    }

    @IBAction func contentViewTapped(_ sender: Any) {
        if(playerDestination == .local) {
            videoControlsView.isHidden = false
            controlsAppearTime = CACurrentMediaTime()
        }
    }

    @IBAction func jumpBackTapped(_ sender: Any) {
        if paused == false {
            if(playerDestination == .local) {
                mediaPlayer.jumpBackward(15)
            } else {
                
            }
        }
    }

    @IBAction func jumpForwardTapped(_ sender: Any) {
        if paused == false {
            if(playerDestination == .local) {
                mediaPlayer.jumpForward(30)
            } else {
            }
        }
    }

    @IBOutlet weak var mainActionButton: UIButton!
    @IBAction func mainActionButtonPressed(_ sender: Any) {
        if paused {
            if(playerDestination == .local) {
                mediaPlayer.play()
                mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
                paused = false
            } else {
                sendCastCommand(cmd: "Unpause")
                mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
                paused = false
            }
        } else {
            if(playerDestination == .local) {
                mediaPlayer.pause()
                mainActionButton.setImage(UIImage(systemName: "play"), for: .normal)
                paused = true
            } else {
                sendCastCommand(cmd: "Pause")
                mainActionButton.setImage(UIImage(systemName: "play"), for: .normal)
                paused = true
            }
        }
    }

    @IBAction func settingsButtonTapped(_ sender: UIButton) {
        optionsVC = VideoPlayerSettingsView()
        optionsVC?.delegate = self

        optionsVC?.modalPresentationStyle = .popover
        optionsVC?.popoverPresentationController?.sourceView = playerSettingsButton

        // Present the view controller (in a popover).
        self.present(optionsVC!, animated: true) {
            print("popover visible, pause playback")
            self.mediaPlayer.pause()
            self.mainActionButton.setImage(UIImage(systemName: "play"), for: .normal)
        }
    }
    
    //MARK: Cast start
    @IBAction func castButtonPressed(_ sender: Any) {
        if(selectedCastDevice == nil) {
            castDeviceVC = VideoPlayerCastDeviceSelectorView()
            castDeviceVC?.delegate = self

            castDeviceVC?.modalPresentationStyle = .popover
            castDeviceVC?.popoverPresentationController?.sourceView = castButton

            // Present the view controller (in a popover).
            self.present(castDeviceVC!, animated: true) {
                print("popover visible, pause playback")
                self.mediaPlayer.pause()
                self.mainActionButton.setImage(UIImage(systemName: "play"), for: .normal)
            }
        } else {
            castClient?.stopCurrentApp()
            castClient?.disconnect()
            selectedCastDevice = nil;
            castClient = nil;
            self.castButton.isEnabled = true
            self.castButton.setImage(UIImage(named: "CastDisconnected"), for: .normal)
            
            //disconnect cast device.
            
        }
    }
    
    func castPopoverDismissed() {
        castDeviceVC?.dismiss(animated: true, completion: nil)
        self.mediaPlayer.play()
        self.mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
    }
    
    func castDeviceChanged() {
        if(selectedCastDevice != nil) {
            castClient = CastClient(device: selectedCastDevice!)
            castClient!.delegate = self
            castClient!.connect()
        }
    }
    
    func sendCastCommand(cmd: String) {
        let payload: [String: Any] = [
            "options": [],
            "command": cmd,
            "userId": SessionManager.current.user.user_id!,
            "deviceId": SessionManager.current.deviceID,
            "accessToken": SessionManager.current.accessToken,
            "serverAddress": ServerEnvironment.current.server.baseURI!,
            "serverId": ServerEnvironment.current.server.server_id!,
            "serverVersion": "10.8.0",
            "receiverName": self.selectedCastDevice!.name
        ]
        let req = CastRequest(id: castClient!.nextRequestId(), namespace: "urn:x-cast:com.connectsdk", destinationId: castAppTransportID, payload: payload)
        castClient!.send(req, response: nil)
    }
    
    func castClient(_ client: CastClient, connectionTo device: CastDevice, didFailWith error: Error?) {
        dump(error)
    }
    
    func castClient(_ client: CastClient, willConnectTo device: CastDevice) {
        print("Connecting")
        mediaPlayer.pause()
        castScanner.stopScanning()
        self.castButton.setImage(UIImage(named: "CastConnecting1"), for: .normal)
    }
    
    func castClient(_ client: CastClient, didConnectTo device: CastDevice) {
        print("Connected")
        self.castButton.setImage(UIImage(named: "CastConnected"), for: .normal)
        
        //Launch player
        client.launch(appId: "F007D354") { result in
                switch result {
                    case .success(let app):
                    // here you would probably call client.load() to load some media
                        let payload: [String: Any] = [
                            "options": [
                                "items": [[
                                    "Id": self.manifest.id!,
                                    "ServerId": ServerEnvironment.current.server.server_id!,
                                    "Name": self.manifest.name!,
                                    "Type": self.manifest.type!,
                                    "MediaType": self.manifest.mediaType!,
                                    "IsFolder": self.manifest.isFolder!
                                ]]
                            ],
                            "command": "PlayNow",
                            "userId": SessionManager.current.user.user_id!,
                            "deviceId": SessionManager.current.deviceID,
                            "accessToken": SessionManager.current.accessToken,
                            "serverAddress": ServerEnvironment.current.server.baseURI!,
                            "serverId": ServerEnvironment.current.server.server_id!,
                            "serverVersion": "10.8.0",
                            "receiverName": self.selectedCastDevice!.name,
                            "subtitleBurnIn": false
                        ]
                        self.castAppTransportID = app.transportId
                        let req = CastRequest(id: client.nextRequestId(), namespace: "urn:x-cast:com.connectsdk", destinationId: app.transportId, payload: payload)
                        client.send(req, response: self.castResponseHandler)
                    case .failure(let error):
                        print(error)
                }
        }
        
        //Hide VLC player
        videoContentView.isHidden = true;
        playerDestination = .remote;
        
    }
    
    func castClient(_ client: CastClient, didDisconnectFrom device: CastDevice) {
        print("Disconnected")
        castScanner.startScanning()
        playerDestination = .local;
        videoContentView.isHidden = false;
        self.castButton.setImage(UIImage(named: "CastDisconnected"), for: .normal)
    }
                            
    func castResponseHandler(result: Result<JSON, CastError>) {
        dump(result)
    }
    
    //MARK: Cast End
    func settingsPopoverDismissed() {
        optionsVC?.dismiss(animated: true, completion: nil)
        if(playerDestination == .local) {
            self.mediaPlayer.play()
            self.mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var shouldAutorotate: Bool {
        return true
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
            if(self.playerDestination == .local) {
                self.mediaPlayer.pause()
                self.sendProgressReport(eventName: "pause")
            } else {
                self.sendCastCommand(cmd: "Pause")
            }
            self.mainActionButton.setImage(UIImage(systemName: "play"), for: .normal)
            return .success
        }

        // Add handler for Play command
        commandCenter.playCommand.addTarget { _ in
            if(self.playerDestination == .local) {
                self.mediaPlayer.play()
                self.sendProgressReport(eventName: "unpause")
            } else {
                self.sendCastCommand(cmd: "Unpause")
            }
            self.mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
            return .success
        }

        // Add handler for FF command
        commandCenter.seekForwardCommand.addTarget { _ in
            if(self.playerDestination == .local) {
                self.mediaPlayer.jumpForward(30)
                self.sendProgressReport(eventName: "timeupdate")
            } else {
                
            }
            return .success
        }

        // Add handler for RW command
        commandCenter.seekBackwardCommand.addTarget { _ in
            if(self.playerDestination == .local) {
                self.mediaPlayer.jumpBackward(15)
                self.sendProgressReport(eventName: "timeupdate")
            }
            return .success
        }

        // Scrubber
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self](remoteEvent) -> MPRemoteCommandHandlerStatus in
            guard let self = self else {return .commandFailed}

            if let event = remoteEvent as? MPChangePlaybackPositionCommandEvent {
                let targetSeconds = event.positionTime
                
                let videoPosition = Double(self.mediaPlayer.time.intValue)
                let offset = targetSeconds - videoPosition
                
                if(self.playerDestination == .local) {
                    if offset > 0 {
                        self.mediaPlayer.jumpForward(Int32(offset)/1000)
                    } else {
                        self.mediaPlayer.jumpBackward(Int32(abs(offset))/1000)
                    }
                    self.sendProgressReport(eventName: "unpause")
                } else {
                    
                }

                return .success
            } else {
                return .commandFailed
            }
        }

        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = manifest.name ?? ""

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    override func remoteControlReceived(with event: UIEvent?) {
        dump(event)
    }

    // MARK: viewDidLoad
    override func viewDidLoad() {
        if manifest.type == "Movie" {
            titleLabel.text = manifest.name ?? ""
        } else {
            titleLabel.text = "S\(String(manifest.parentIndexNumber ?? 0)):E\(String(manifest.indexNumber ?? 0)) “\(manifest.name ?? "")”"
        }

        super.viewDidLoad()
        if !UIDevice.current.orientation.isLandscape {
            let value = UIInterfaceOrientation.landscapeLeft.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
        }
    }

    func mediaHasStartedPlaying() {
        NotificationCenter.default.addObserver(forName: CastDeviceScanner.deviceListDidChange, object: castScanner, queue: nil) { _ in
            self.discoveredCastDevices = self.castScanner.devices
            if !self.castScanner.devices.isEmpty {
                self.castButton.isEnabled = true
                self.castButton.setImage(UIImage(named: "CastDisconnected"), for: .normal)
            } else {
                self.castButton.isEnabled = false
                self.castButton.setImage(nil, for: .normal)
            }
        }

        castScanner.startScanning()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        overrideUserInterfaceStyle = .dark
        self.tabBarController?.tabBar.isHidden = true
        // View has loaded.

        mediaPlayer.perform(Selector(("setTextRendererFontSize:")), with: 14)
        // mediaPlayer.wrappedValue.perform(Selector(("setTextRendererFont:")), with: "Copperplate")

        mediaPlayer.delegate = self
        mediaPlayer.drawable = videoContentView

        // Fetch max bitrate from UserDefaults depending on current connection mode
        let defaults = UserDefaults.standard
        let maxBitrate = defaults.integer(forKey: "InNetworkBandwidth")

        // Build a device profile
        let builder = DeviceProfileBuilder()
        builder.setMaxBitrate(bitrate: maxBitrate)
        let profile = builder.buildProfile()

        let playbackInfo = PlaybackInfoDto(userId: SessionManager.current.user.user_id!, maxStreamingBitrate: Int(maxBitrate), startTimeTicks: manifest.userData?.playbackPositionTicks ?? 0, deviceProfile: profile, autoOpenLiveStream: true)

        DispatchQueue.global(qos: .userInitiated).async { [self] in
            delegate?.showLoadingView(self)
            MediaInfoAPI.getPostedPlaybackInfo(itemId: manifest.id!, userId: SessionManager.current.user.user_id!, maxStreamingBitrate: Int(maxBitrate), startTimeTicks: manifest.userData?.playbackPositionTicks ?? 0, autoOpenLiveStream: true, playbackInfoDto: playbackInfo)
                .sink(receiveCompletion: { result in
                    print(result)
                }, receiveValue: { [self] response in
                    videoContentView.setNeedsLayout()
                    videoContentView.setNeedsDisplay()
                    playSessionId = response.playSessionId ?? ""
                    let mediaSource = response.mediaSources!.first.self!
                    if mediaSource.transcodingUrl != nil {
                        // Item is being transcoded by request of server
                        let streamURL = URL(string: "\(ServerEnvironment.current.server.baseURI!)\(mediaSource.transcodingUrl!)")
                        let item = PlaybackItem()
                        item.videoType = .transcode
                        item.videoUrl = streamURL!

                        let disableSubtitleTrack = Subtitle(name: "Disabled", id: -1, url: nil, delivery: .embed, codec: "")
                        subtitleTrackArray.append(disableSubtitleTrack)

                        // Loop through media streams and add to array
                        for stream in mediaSource.mediaStreams! {
                            if stream.type == .subtitle {
                                var deliveryUrl: URL?
                                if stream.deliveryMethod == .external {
                                    deliveryUrl = URL(string: "\(ServerEnvironment.current.server.baseURI!)\(stream.deliveryUrl!)")!
                                } else {
                                    deliveryUrl = nil
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

                        if selectedAudioTrack == -1 {
                            if audioTrackArray.count > 0 {
                                selectedAudioTrack = audioTrackArray[0].id
                            }
                        }

                        self.sendPlayReport()
                        playbackItem = item
                    } else {
                        // Item will be directly played by the client.
                        let streamURL: URL = URL(string: "\(ServerEnvironment.current.server.baseURI!)/Videos/\(manifest.id!)/stream?Static=true&mediaSourceId=\(manifest.id!)&deviceId=\(SessionManager.current.deviceID)&api_key=\(SessionManager.current.accessToken)&Tag=\(mediaSource.eTag!)")!

                        let item = PlaybackItem()
                        item.videoUrl = streamURL
                        item.videoType = .directPlay

                        let disableSubtitleTrack = Subtitle(name: "Disabled", id: -1, url: nil, delivery: .embed, codec: "")
                        subtitleTrackArray.append(disableSubtitleTrack)

                        // Loop through media streams and add to array
                        for stream in mediaSource.mediaStreams! {
                            if stream.type == .subtitle {
                                var deliveryUrl: URL?
                                if stream.deliveryMethod == .external {
                                    deliveryUrl = URL(string: "\(ServerEnvironment.current.server.baseURI!)\(stream.deliveryUrl!)")!
                                } else {
                                    deliveryUrl = nil
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

                        if selectedAudioTrack == -1 {
                            if audioTrackArray.count > 0 {
                                selectedAudioTrack = audioTrackArray[0].id
                            }
                        }

                        print("gotToEnd")

                        self.sendPlayReport()
                        playbackItem = item
                    }

                    mediaPlayer.media = VLCMedia(url: playbackItem.videoUrl)
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
                    delegate?.showLoadingView(self)

                    while mediaPlayer.numberOfSubtitlesTracks != shouldHaveSubtitleTracks {}

                    // Select default track & resume playback
                    mediaPlayer.currentVideoSubTitleIndex = selectedCaptionTrack
                    mediaPlayer.pause()
                    mediaPlayer.play()
                    self.mediaHasStartedPlaying()
                })
                .store(in: &cancellables)
        }
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

    // MARK: VLCMediaPlayer Delegates
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
            let currentState: VLCMediaPlayerState = mediaPlayer.state
            switch currentState {
            case .stopped :
                break
            case .ended :
                break
            case .playing :
                print("Video is playing")
                self.setupNowPlayingCC()
                sendProgressReport(eventName: "unpause")
                delegate?.hideLoadingView(self)
                paused = false

            case .paused :
                print("Video is paused)")
                paused = true

            case .opening :
                print("Video is opening)")

            case .buffering :
                print("Video is buffering)")
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
        let time = mediaPlayer.position
        if time != lastTime {
            paused = false
            mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
            seekSlider.setValue(mediaPlayer.position, animated: true)
            delegate?.hideLoadingView(self)

            let remainingTime = abs(mediaPlayer.remainingTime.intValue)/1000
            let hours = remainingTime / 3600
            let minutes = (remainingTime % 3600) / 60
            let seconds = (remainingTime % 3600) % 60
            var timeTextStr = ""
            if hours != 0 {
                timeTextStr = "\(Int(hours)):\(String(Int((minutes))).leftPad(toWidth: 2, withString: "0")):\(String(Int((seconds))).leftPad(toWidth: 2, withString: "0"))"
            } else {
                timeTextStr = "\(String(Int((minutes))).leftPad(toWidth: 2, withString: "0")):\(String(Int((seconds))).leftPad(toWidth: 2, withString: "0"))"
            }
            timeText.text = timeTextStr

            if CACurrentMediaTime() - controlsAppearTime > 5 {
                UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                    self.videoControlsView.alpha = 0.0
                }, completion: { (_: Bool) in
                    self.videoControlsView.isHidden = true
                    self.videoControlsView.alpha = 1
                })
                controlsAppearTime = 999_999_999_999_999
            }
        } else {
            paused = true
        }
        lastTime = time

        if CACurrentMediaTime() - lastProgressReportTime > 5 {
            sendProgressReport(eventName: "timeupdate")
            lastProgressReportTime = CACurrentMediaTime()
        }
    }

    // MARK: Jellyfin Playstate updates
    func sendProgressReport(eventName: String) {
        if (eventName == "timeupdate" && mediaPlayer.state == .playing) || eventName != "timeupdate" {
            let progressInfo = PlaybackProgressInfo(canSeek: true, item: manifest, itemId: manifest.id, sessionId: playSessionId, mediaSourceId: manifest.id, audioStreamIndex: Int(selectedAudioTrack), subtitleStreamIndex: Int(selectedCaptionTrack), isPaused: (mediaPlayer.state == .paused), isMuted: false, positionTicks: Int64(mediaPlayer.position * Float(manifest.runTimeTicks!)), playbackStartTimeTicks: Int64(startTime), volumeLevel: 100, brightness: 100, aspectRatio: nil, playMethod: playbackItem.videoType, liveStreamId: nil, playSessionId: playSessionId, repeatMode: .repeatNone, nowPlayingQueue: [], playlistItemId: "playlistItem0")

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
}

struct VLCPlayerWithControls: UIViewControllerRepresentable {
    var item: BaseItemDto
    @Environment(\.presentationMode) var presentationMode

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
            self.loadBinding.wrappedValue = false
        }

        func showLoadingView(_ viewController: PlayerViewController) {
            self.loadBinding.wrappedValue = true
        }

        func exitPlayer(_ viewController: PlayerViewController) {
            self.pBinding.wrappedValue = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(loadBinding: self.loadBinding, pBinding: self.pBinding)
    }

    typealias UIViewControllerType = PlayerViewController
    func makeUIViewController(context: UIViewControllerRepresentableContext<VLCPlayerWithControls>) -> VLCPlayerWithControls.UIViewControllerType {
        let storyboard = UIStoryboard(name: "VideoPlayer", bundle: nil)
        let customViewController = storyboard.instantiateViewController(withIdentifier: "VideoPlayer") as! PlayerViewController
        customViewController.manifest = item
        customViewController.delegate = context.coordinator
        return customViewController
    }

    func updateUIViewController(_ uiViewController: VLCPlayerWithControls.UIViewControllerType, context: UIViewControllerRepresentableContext<VLCPlayerWithControls>) {
    }
}
