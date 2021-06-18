//
//  CastApp.swift
//  OpenCastSwift
//
//  Created by Miles Hollingsworth on 4/22/18
//  Copyright © 2018 Miles Hollingsworth. All rights reserved.
//

import Foundation
import SwiftyJSON

public struct CastAppIdentifier {
  public static let defaultMediaPlayer = "CC1AD845"
  public static let youTube = "YouTube"
  public static let googleAssistant = "97216CB6"
}

public final class CastApp: NSObject {
  public var id: String = ""
  public var displayName: String = ""
  public var isIdleScreen: Bool = false
  public var sessionId: String = ""
  public var statusText: String = ""
  public var transportId: String = ""
  public var namespaces = [String]()
  
  convenience init(json: JSON) {
    self.init()
    
    if let id = json[CastJSONPayloadKeys.appId].string {
      self.id = id
    }
    
    if let displayName = json[CastJSONPayloadKeys.displayName].string {
      self.displayName = displayName
    }
    
    if let isIdleScreen = json[CastJSONPayloadKeys.isIdleScreen].bool {
      self.isIdleScreen = isIdleScreen
    }
    
    if let sessionId = json[CastJSONPayloadKeys.sessionId].string {
      self.sessionId = sessionId
    }
    
    if let statusText = json[CastJSONPayloadKeys.statusText].string {
      self.statusText = statusText
    }
    
    if let transportId = json[CastJSONPayloadKeys.transportId].string {
      self.transportId = transportId
    }
    
    if let namespaces = json[CastJSONPayloadKeys.namespaces].array {
      self.namespaces = namespaces.compactMap { $0[CastJSONPayloadKeys.name].string }
    }
  }
  
  public override var description: String {
    return "CastApp(id: \(id), displayName: \(displayName), isIdleScreen: \(isIdleScreen), sessionId: \(sessionId), statusText: \(statusText), transportId: \(transportId), namespaces: \(namespaces)"
  }
}
