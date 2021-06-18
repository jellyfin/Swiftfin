//
//  CastMediaStatus.swift
//  OpenCastSwift
//
//  Created by Miles Hollingsworth on 4/22/18
//  Copyright © 2018 Miles Hollingsworth. All rights reserved.
//

import Foundation
import SwiftyJSON

public enum CastMediaPlayerState: String {
  case buffering = "BUFFERING"
  case playing = "PLAYING"
  case paused = "PAUSED"
  case stopped = "STOPPED"
}

public final class CastMediaStatus: NSObject {
  
  public let mediaSessionId: Int
  public let playbackRate: Int
  public let playerState: CastMediaPlayerState
  public let currentTime: Double
  public let metadata: JSON?
  public let contentID: String?
  private let createdDate = Date()
  
  public var adjustedCurrentTime: Double {
    return currentTime - Double(playbackRate)*createdDate.timeIntervalSinceNow
  }
  
  public var state: String {
    return playerState.rawValue
  }
  
  public override var description: String {
    return "MediaStatus(mediaSessionId: \(mediaSessionId), playbackRate: \(playbackRate), playerState: \(playerState.rawValue), currentTime: \(currentTime))"
  }
  
  init(json: JSON) {
    mediaSessionId = json[CastJSONPayloadKeys.mediaSessionId].int ?? 0
    
    playbackRate = json[CastJSONPayloadKeys.playbackRate].int ?? 1
    
    playerState = json[CastJSONPayloadKeys.playerState].string.flatMap(CastMediaPlayerState.init) ?? .buffering
    
    currentTime = json[CastJSONPayloadKeys.currentTime].double ?? 0
    
    metadata = json[CastJSONPayloadKeys.media][CastJSONPayloadKeys.metadata]
    
    if let contentID = json[CastJSONPayloadKeys.media][CastJSONPayloadKeys.contentId].string, let data = contentID.data(using: .utf8) {
      self.contentID = (try? JSON(data: data))?[CastJSONPayloadKeys.contentId].string ?? contentID
    } else {
      contentID = nil
    }
    
    super.init()
  }
}
