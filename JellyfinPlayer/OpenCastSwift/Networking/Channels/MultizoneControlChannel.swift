//
//  MultizoneControlChannel.swift
//  OpenCastSwift Mac
//
//  Created by Miles Hollingsworth on 4/22/18
//  Copyright © 2018 Miles Hollingsworth. All rights reserved.
//

import Foundation
import Result
import SwiftyJSON

class MultizoneControlChannel: CastChannel {
  override weak var requestDispatcher: RequestDispatchable! {
    didSet {
      if let _ = requestDispatcher {
        requestStatus()
      }
    }
  }

  private var delegate: MultizoneControlChannelDelegate? {
    return requestDispatcher as? MultizoneControlChannelDelegate
  }

  init() {
    super.init(namespace: CastNamespace.multizone)
  }

  override func handleResponse(_ json: JSON, sourceId: String) {
    guard let rawType = json["type"].string else { return }

    guard let type = CastMessageType(rawValue: rawType) else {
      print("Unknown type: \(rawType)")
      print(json)
      return
    }

    switch type {
    case .multizoneStatus:
      delegate?.channel(self, didReceive: CastMultizoneStatus(json: json))

    case .deviceAdded:
      let device = CastMultizoneDevice(json: json[CastJSONPayloadKeys.device])
      delegate?.channel(self, added: device)

    case .deviceUpdated:
      let device = CastMultizoneDevice(json: json[CastJSONPayloadKeys.device])
      delegate?.channel(self, updated: device)

    case .deviceRemoved:
      guard let deviceId = json[CastJSONPayloadKeys.deviceId].string else { return }
      delegate?.channel(self, removed: deviceId)

    default:
      print(rawType)
      print(json)
    }
  }

  public func requestStatus(completion: ((Result<CastStatus, CastError>) -> Void)? = nil) {
    let request = requestDispatcher.request(withNamespace: namespace,
                               destinationId: CastConstants.receiver,
                               payload: [CastJSONPayloadKeys.type: CastMessageType.statusRequest.rawValue])

    if let completion = completion {
      send(request) { result in
        switch result {
        case .success(let json):
          completion(Result(value: CastStatus(json: json)))

        case .failure(let error):
          completion(Result(error: error))
        }
      }
    } else {
      send(request)
    }
  }

  public func setVolume(_ volume: Float, for device: CastMultizoneDevice) {
    let payload: [String: Any] = [
      CastJSONPayloadKeys.type: CastMessageType.setDeviceVolume.rawValue,
      CastJSONPayloadKeys.volume: [CastJSONPayloadKeys.level: volume],
      CastJSONPayloadKeys.deviceId: device.id
    ]

    let request = requestDispatcher.request(withNamespace: namespace,
                               destinationId: CastConstants.receiver,
                               payload: payload)

    send(request)
  }

  public func setMuted(_ isMuted: Bool, for device: CastMultizoneDevice) {
    let payload: [String: Any] = [
      CastJSONPayloadKeys.type: CastMessageType.setVolume.rawValue,
      CastJSONPayloadKeys.volume: [CastJSONPayloadKeys.muted: isMuted],
      CastJSONPayloadKeys.deviceId: device.id
    ]

    let request = requestDispatcher.request(withNamespace: namespace,
                               destinationId: CastConstants.receiver,
                               payload: payload)

    send(request)
  }
}

protocol MultizoneControlChannelDelegate: AnyObject {
  func channel(_ channel: MultizoneControlChannel, didReceive status: CastMultizoneStatus)
  func channel(_ channel: MultizoneControlChannel, added device: CastMultizoneDevice)
  func channel(_ channel: MultizoneControlChannel, updated device: CastMultizoneDevice)
  func channel(_ channel: MultizoneControlChannel, removed deviceId: String)
}
