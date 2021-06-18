//
//  CastMultizoneDevice.swift
//  OpenCastSwift Mac
//
//  Created by Miles Hollingsworth on 4/22/18
//  Copyright © 2018 Miles Hollingsworth. All rights reserved.
//

import Foundation
import SwiftyJSON

public class CastMultizoneDevice {
  public let name: String
  public let volume: Float
  public let isMuted: Bool
  public let capabilities: DeviceCapabilities
  public let id: String
  
  public init(name: String, volume: Float, isMuted: Bool, capabilitiesMask: Int, id: String) {
    self.name = name
    self.volume = volume
    self.isMuted = isMuted
    capabilities = DeviceCapabilities(rawValue: capabilitiesMask)
    self.id = id
  }
}

extension CastMultizoneDevice {
  convenience init(json: JSON) {
    let name = json[CastJSONPayloadKeys.name].stringValue
    
    let volumeValues = json[CastJSONPayloadKeys.volume]
    
    let volume = volumeValues[CastJSONPayloadKeys.level].floatValue
    let isMuted = volumeValues[CastJSONPayloadKeys.muted].boolValue
    let capabilitiesMask = json[CastJSONPayloadKeys.capabilities].intValue
    let deviceId = json[CastJSONPayloadKeys.deviceId].stringValue
    
    self.init(name: name, volume: volume, isMuted: isMuted, capabilitiesMask: capabilitiesMask, id: deviceId)
  }
  
}
