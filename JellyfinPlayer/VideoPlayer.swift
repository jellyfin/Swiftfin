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
import GoogleCast
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

class PlayerViewController: UIViewController, GCKDiscoveryManagerListener, GCKRemoteMediaClientListener {

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
    var isSeeking: Bool = false
    
    var playerDestination: PlayerDestination = .local;
    var discoveredCastDevices: [GCKDevice] = [];
    var selectedCastDevice: GCKDevice?;
    var jellyfinCastChannel: GCKGenericChannel?
    var remotePositionTicks: Int = 0
    private var castDiscoveryManager: GCKDiscoveryManager {
        return GCKCastContext.sharedInstance().discoveryManager
    }
    private var castSessionManager: GCKSessionManager {
        return GCKCastContext.sharedInstance().sessionManager
    }
    var hasSentRemoteSeek: Bool = false;

    var selectedAudioTrack: Int32 = -1
    var selectedCaptionTrack: Int32 = -1
    var playSessionId: String = ""
    var lastProgressReportTime: Double = 0
    var subtitleTrackArray: [Subtitle] = []
    var audioTrackArray: [AudioTrack] = []

    var manifest: BaseItemDto = BaseItemDto()
    var playbackItem = PlaybackItem()
    var remoteTimeUpdateTimer: Timer?
    

    // MARK: IBActions
    @IBAction func seekSliderStart(_ sender: Any) {
        if(playerDestination == .local) {
            sendProgressReport(eventName: "pause")
            mediaPlayer.pause()
        } else {
            isSeeking = true
        }
    }

    @IBAction func seekSliderValueChanged(_ sender: Any) {
        let videoDuration: Double = Double(manifest.runTimeTicks! / Int64(10_000_000))
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
        isSeeking = false
        let videoPosition = playerDestination == .local ? Double(mediaPlayer.time.intValue / 1000) : Double(remotePositionTicks / Int(10_000_000))
        let videoDuration = Double(manifest.runTimeTicks! / Int64(10_000_000))
        // Scrub is value from 0..1 - find position in video and add / or remove.
        let secondsScrubbedTo = round(Double(seekSlider.value) * videoDuration)
        let offset = secondsScrubbedTo - videoPosition
        
        if(playerDestination == .local) {
            if offset > 0 {
                mediaPlayer.jumpForward(Int32(offset))
            } else {
                mediaPlayer.jumpBackward(Int32(abs(offset)))
            }
            mediaPlayer.play()
            sendProgressReport(eventName: "unpause")
        } else {
            sendJellyfinCommand(command: "Seek", options: [
                "position": Int(secondsScrubbedTo)
            ])
        }
    }

    @IBAction func exitButtonPressed(_ sender: Any) {
        sendStopReport()
        mediaPlayer.stop()
        
        if(castSessionManager.hasConnectedCastSession()) {
            castSessionManager.endSessionAndStopCasting(true)
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
                self.sendJellyfinCommand(command: "Seek", options: ["position": (remotePositionTicks/10_000_000)-15])
            }
        }
    }

    @IBAction func jumpForwardTapped(_ sender: Any) {
        if paused == false {
            if(playerDestination == .local) {
                mediaPlayer.jumpForward(30)
            } else {
                self.sendJellyfinCommand(command: "Seek", options: ["position": (remotePositionTicks/10_000_000)+30])
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
                sendJellyfinCommand(command: "Unpause", options: [:])
                mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
                paused = false
            }
        } else {
            if(playerDestination == .local) {
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
    
    //MARK: Cast methods
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
            castSessionManager.endSessionAndStopCasting(true)
            selectedCastDevice = nil;
            self.castButton.isEnabled = true
            self.castButton.setImage(UIImage(named: "CastDisconnected"), for: .normal)
            playerDestination = .local
        }
    }
    
    func castPopoverDismissed() {
        castDeviceVC?.dismiss(animated: true, completion: nil)
        if(playerDestination == .local) {
            self.mediaPlayer.play()
        }
        self.mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
    }
    
    func castDeviceChanged() {
        if(selectedCastDevice != nil) {
            playerDestination = .remote
            castSessionManager.add(self)
            castSessionManager.startSession(with: selectedCastDevice!)
        }
    }
    
    //MARK: Cast End
    func settingsPopoverDismissed() {
        optionsVC?.dismiss(animated: true, completion: nil)
        if(playerDestination == .local) {
            self.mediaPlayer.play()
            self.mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
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
            if(self.playerDestination == .local) {
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
            if(self.playerDestination == .local) {
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
            if(self.playerDestination == .local) {
                self.mediaPlayer.jumpForward(30)
                self.sendProgressReport(eventName: "timeupdate")
            } else {
                self.sendJellyfinCommand(command: "Seek", options: ["position": (self.remotePositionTicks/10_000_000)+30])
            }
            return .success
        }

        // Add handler for RW command
        commandCenter.seekBackwardCommand.addTarget { _ in
            if(self.playerDestination == .local) {
                self.mediaPlayer.jumpBackward(15)
                self.sendProgressReport(eventName: "timeupdate")
            } else {
                self.sendJellyfinCommand(command: "Seek", options: ["position": (self.remotePositionTicks/10_000_000)-15])
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

    // MARK: viewDidLoad
    override func viewDidLoad() {
        if manifest.type == "Movie" {
            titleLabel.text = manifest.name ?? ""
        } else {
            titleLabel.text = "S\(String(manifest.parentIndexNumber ?? 0)):E\(String(manifest.indexNumber ?? 0)) “\(manifest.name ?? "")”"
        }

        super.viewDidLoad()
    }

    func mediaHasStartedPlaying() {
        castButton.isHidden = true;
        let discoveryCriteria = GCKDiscoveryCriteria(applicationID: "F007D354")
        let gckCastOptions = GCKCastOptions(discoveryCriteria: discoveryCriteria)
        GCKCastContext.setSharedInstanceWith(gckCastOptions)
        castDiscoveryManager.passiveScan = true
        castDiscoveryManager.add(self)
        castDiscoveryManager.startDiscovery()
    }
    
    func didUpdateDeviceList() {
        let totalDevices = castDiscoveryManager.deviceCount;
        discoveredCastDevices = []
        if(totalDevices > 0) {
            for i in 0...totalDevices-1 {
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
    
    //MARK: viewDidAppear
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        overrideUserInterfaceStyle = .dark
        self.tabBarController?.tabBar.isHidden = true
        self.navigationController?.isNavigationBarHidden = true

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
                        for stream in mediaSource.mediaStreams ?? [] {
                            if stream.type == .subtitle {
                                var deliveryUrl: URL?
                                if stream.deliveryMethod == .external {
                                    deliveryUrl = URL(string: "\(ServerEnvironment.current.server.baseURI!)\(stream.deliveryUrl ?? "")")!
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
                        let streamURL: URL = URL(string: "\(ServerEnvironment.current.server.baseURI!)/Videos/\(manifest.id!)/stream?Static=true&mediaSourceId=\(manifest.id!)&deviceId=\(SessionManager.current.deviceID)&api_key=\(SessionManager.current.accessToken)&Tag=\(mediaSource.eTag ?? "")")!

                        let item = PlaybackItem()
                        item.videoUrl = streamURL
                        item.videoType = .directPlay

                        let disableSubtitleTrack = Subtitle(name: "Disabled", id: -1, url: nil, delivery: .embed, codec: "")
                        subtitleTrackArray.append(disableSubtitleTrack)

                        // Loop through media streams and add to array
                        for stream in mediaSource.mediaStreams ?? [] {
                            if stream.type == .subtitle {
                                var deliveryUrl: URL?
                                if stream.deliveryMethod == .external {
                                    deliveryUrl = URL(string: "\(ServerEnvironment.current.server.baseURI!)\(stream.deliveryUrl!)")!
                                } else {
                                    deliveryUrl = nil
                                }
                                let subtitle = Subtitle(name: stream.displayTitle ?? "Unknown", id: Int32(stream.index!), url: deliveryUrl, delivery: stream.deliveryMethod!, codec: stream.codec!)

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
                    }

                    startLocalPlaybackEngine(true)
                })
                .store(in: &cancellables)
        }
    }

    func startLocalPlaybackEngine(_ fetchCaptions: Bool) {
        print("Local playback engine starting.")
        mediaPlayer.media = VLCMedia(url: playbackItem.videoUrl)
        mediaPlayer.play()
        sendPlayReport()

        // 1 second = 10,000,000 ticks
        var startTicks: Int64 = 0;
        if(remotePositionTicks == 0) {
            print("Using server-reported start time")
            startTicks = manifest.userData?.playbackPositionTicks ?? 0
        } else {
            print("Using remote-reported start time")
            startTicks = Int64(remotePositionTicks)
        }
        
        if startTicks != 0 {
            let videoPosition = Double(mediaPlayer.time.intValue / 1000);
            let secondsScrubbedTo = startTicks / 10_000_000
            let offset = secondsScrubbedTo - Int64(videoPosition)
            print("Seeking to position: \(secondsScrubbedTo)")
            if offset > 0 {
                mediaPlayer.jumpForward(Int32(offset))
            } else {
                mediaPlayer.jumpBackward(Int32(abs(offset)))
            }
        }
        
        if(fetchCaptions) {
            print("Fetching captions.")
            // Pause and load captions into memory.
            mediaPlayer.pause()
            subtitleTrackArray.forEach { sub in
                if sub.id != -1 && sub.delivery == .external {
                    mediaPlayer.addPlaybackSlave(sub.url!, type: .subtitle, enforce: false)
                }
            }
        }
        
        self.mediaHasStartedPlaying()
        delegate?.hideLoadingView(self)
        
        videoContentView.setNeedsLayout()
        videoContentView.setNeedsDisplay()
        self.view.setNeedsLayout()
        self.view.setNeedsDisplay()
        self.videoControlsView.setNeedsLayout()
        self.videoControlsView.setNeedsDisplay()
        
        mediaPlayer.pause()
        mediaPlayer.play()
        
        print("Local engine started.")
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
}

//MARK: - GCKGenericChannelDelegate
extension PlayerViewController: GCKGenericChannelDelegate {
    @objc func updateRemoteTime() {
        castButton.setImage(UIImage(named: "CastConnected"), for: .normal)
        if(!paused) {
            remotePositionTicks = remotePositionTicks + 2_000_000; //add 0.2 secs every timer evt.
        }
        
        if(isSeeking == false) {
            let remainingTime = (manifest.runTimeTicks! - Int64(remotePositionTicks))/10_000_000
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
            
            let playbackProgress = Float(remotePositionTicks) / Float(manifest.runTimeTicks!)
            seekSlider.setValue(playbackProgress, animated: true)
        }
    }
    
    func cast(_ channel: GCKGenericChannel, didReceiveTextMessage message: String, withNamespace protocolNamespace: String) {
        if let data = message.data(using: .utf8) {
            if let json = try? JSON(data: data) {
                let messageType = json["type"].string ?? ""
                if(messageType == "playbackprogress") {
                    dump(json)
                    if(remotePositionTicks > 100) {
                        if(hasSentRemoteSeek == false) {
                            hasSentRemoteSeek = true;
                            sendJellyfinCommand(command: "Seek", options: [
                                "position": Int(Float(manifest.runTimeTicks! / 10_000_000) * mediaPlayer.position)
                            ])
                        }
                    }
                    paused = json["data"]["PlayState"]["IsPaused"].boolValue
                    self.remotePositionTicks = json["data"]["PlayState"]["PositionTicks"].int ?? 0;
                    if(remoteTimeUpdateTimer == nil) {
                        remoteTimeUpdateTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(updateRemoteTime), userInfo: nil, repeats: true)
                    }
                }
            }
        }
    }
    
    func sendJellyfinCommand(command: String, options: [String: Any]) {
        let payload: [String: Any] = [
            "options": options,
            "command": command,
            "userId": SessionManager.current.user.user_id!,
            "deviceId": SessionManager.current.deviceID,
            "accessToken": SessionManager.current.accessToken,
            "serverAddress": ServerEnvironment.current.server.baseURI!,
            "serverId": ServerEnvironment.current.server.server_id!,
            "serverVersion": "10.8.0",
            "receiverName": castSessionManager.currentCastSession!.device.friendlyName!,
            "subtitleBurnIn": false
        ]
        print(payload)
        let jsonData = JSON(payload)
        
        jellyfinCastChannel?.sendTextMessage(jsonData.rawString()!, error: nil)
        
        if(command == "Seek") {
            remotePositionTicks = remotePositionTicks + ((options["position"] as! Int) * 10_000_000)
            //Send playback report as Jellyfin Chromecast isn't smarter than a rock.
            let progressInfo = PlaybackProgressInfo(canSeek: true, item: manifest, itemId: manifest.id, sessionId: playSessionId, mediaSourceId: manifest.id, audioStreamIndex: Int(selectedAudioTrack), subtitleStreamIndex: Int(selectedCaptionTrack), isPaused: paused, isMuted: false, positionTicks: Int64(remotePositionTicks), playbackStartTimeTicks: Int64(startTime), volumeLevel: 100, brightness: 100, aspectRatio: nil, playMethod: playbackItem.videoType, liveStreamId: nil, playSessionId: playSessionId, repeatMode: .repeatNone, nowPlayingQueue: [], playlistItemId: "playlistItem0")

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

//MARK: - GCKSessionManagerListener
extension PlayerViewController: GCKSessionManagerListener {
    func sessionDidStart(manager: GCKSessionManager, didStart session: GCKCastSession) {
        self.sendStopReport()
        mediaPlayer.stop()
        
        playerDestination = .remote
        videoContentView.isHidden = true;
        videoControlsView.isHidden = false;
        castButton.setImage(UIImage(named: "CastConnected"), for: .normal)
        manager.currentCastSession?.start()
        
        jellyfinCastChannel!.delegate = self
        session.add(jellyfinCastChannel!)
        
        if let client = session.remoteMediaClient {
            client.add(self)
        }
        
        let playNowOptions: [String: Any] = [
            "items": [[
                "Id": self.manifest.id!,
                "ServerId": ServerEnvironment.current.server.server_id!,
                "Name": self.manifest.name!,
                "Type": self.manifest.type!,
                "MediaType": self.manifest.mediaType!,
                "IsFolder": self.manifest.isFolder!
            ]]
        ]
        sendJellyfinCommand(command: "PlayNow", options: playNowOptions)
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKCastSession) {
        print("starting session")
        self.jellyfinCastChannel = GCKGenericChannel(namespace: "urn:x-cast:com.connectsdk")
        self.sessionDidStart(manager: sessionManager, didStart: session)
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
        self.jellyfinCastChannel = GCKGenericChannel(namespace: "urn:x-cast:com.connectsdk")
        print("resuming session")
        self.sessionDidStart(manager: sessionManager, didStart: session)
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKCastSession, withError error: Error) {
        dump(error)
    }
    

    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKCastSession, withError error: Error?) {
        print("didEnd")
        playerDestination = .local;
        videoContentView.isHidden = false;
        remoteTimeUpdateTimer?.invalidate()
        castButton.setImage(UIImage(named: "CastDisconnected"), for: .normal)
        startLocalPlaybackEngine(false)
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didSuspend session: GCKCastSession, with reason: GCKConnectionSuspendReason) {
        print("didSuspend")
        playerDestination = .local;
        videoContentView.isHidden = false;
        remoteTimeUpdateTimer?.invalidate()
        castButton.setImage(UIImage(named: "CastDisconnected"), for: .normal)
        startLocalPlaybackEngine(false)
    }
}

//MARK: - VLCMediaPlayer Delegates
extension PlayerViewController: VLCMediaPlayerDelegate {
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
        if abs(time-lastTime) > 0.00005 {
            paused = false
            mainActionButton.setImage(UIImage(systemName: "pause"), for: .normal)
            seekSlider.setValue(mediaPlayer.position, animated: true)
            delegate?.hideLoadingView(self)

            timeText.text = String(mediaPlayer.remainingTime.stringValue.dropFirst())

            if CACurrentMediaTime() - controlsAppearTime > 5 {
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












//MARK: End VideoPlayerVC
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

//MARK: - Play State Update Methods
extension PlayerViewController {
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
        startTime = Int(Date().timeIntervalSince1970) * 10_000_000

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

extension UINavigationController {
    open override var childForHomeIndicatorAutoHidden: UIViewController? {
        return nil
    }
}
