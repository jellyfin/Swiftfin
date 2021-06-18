//
//  CastDevice.swift
//  OpenCastSwift
//
//  Created by Miles Hollingsworth on 4/22/18
//  Copyright © 2018 Miles Hollingsworth. All rights reserved.
//

import Foundation

public struct DeviceCapabilities: OptionSet {
  public let rawValue: Int
  public init(rawValue: Int) { self.rawValue = rawValue }

  public static let none = DeviceCapabilities([])
  public static let videoOut = DeviceCapabilities(rawValue: 1 << 0)
  public static let videoIn = DeviceCapabilities(rawValue: 1 << 1)
  public static let audioOut = DeviceCapabilities(rawValue: 1 << 2)
  public static let audioIn = DeviceCapabilities(rawValue: 1 << 3)
  public static let multizoneGroup = DeviceCapabilities(rawValue: 1 << 5)
  public static let masterVolume = DeviceCapabilities(rawValue: 1 << 11)
  public static let attenuationVolume = DeviceCapabilities(rawValue: 1 << 12)
}

public final class CastDevice: NSObject, NSCopying {

  public private(set) var id: String
  public private(set) var name: String
  public private(set) var modelName: String
  public private(set) var hostName: String
  public private(set) var ipAddress: String
  public private(set) var port: Int
  public private(set) var capabilities: DeviceCapabilities
  public private(set) var status: String
  public private(set) var iconPath: String

  init(id: String, name: String, modelName: String, hostName: String, ipAddress: String, port: Int, capabilitiesMask: Int, status: String, iconPath: String) {
    self.id = id
    self.name = name
    self.modelName = modelName
    self.hostName = hostName
    self.ipAddress = ipAddress
    self.port = port
    capabilities = DeviceCapabilities(rawValue: capabilitiesMask)
    self.status = status
    self.iconPath = iconPath

    super.init()
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    return CastDevice(id: self.id,
                      name: self.name,
                      modelName: self.modelName,
                      hostName: self.hostName,
                      ipAddress: self.ipAddress,
                      port: self.port,
                      capabilitiesMask: capabilities.rawValue,
                      status: self.status,
                      iconPath: iconPath)
  }

  public override var description: String {
    return "CastDevice(id: \(id), name: \(name), hostName:\(hostName), ipAddress:\(ipAddress), port:\(port))"
  }
}
