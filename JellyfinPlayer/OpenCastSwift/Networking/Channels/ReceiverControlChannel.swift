//
//  ReceiverControlChannel.swift
//  OpenCastSwift
//
//  Created by Miles Hollingsworth on 4/22/18
//  Copyright © 2018 Miles Hollingsworth. All rights reserved.
//

import Foundation
import Result
import SwiftyJSON

class ReceiverControlChannel: CastChannel {
  override weak var requestDispatcher: RequestDispatchable! {
    didSet {
      if let _ = requestDispatcher {
        requestStatus()
      }
    }
  }
  
  private var delegate: ReceiverControlChannelDelegate? {
    return requestDispatcher as? ReceiverControlChannelDelegate
  }
  
  init() {
    super.init(namespace: CastNamespace.receiver)
  }
  
  override func handleResponse(_ json: JSON, sourceId: String) {
    guard let rawType = json["type"].string else { return }
    
    guard let type = CastMessageType(rawValue: rawType) else {
      print("Unknown type: \(rawType)")
      print(json)
      return
    }
    
    switch type {
    case .status:
      delegate?.channel(self, didReceive: CastStatus(json: json))
      
    default:
      print(rawType)
    }
  }
  
  public func getAppAvailability(apps: [CastApp], completion: @escaping (Result<AppAvailability, CastError>) -> Void) {
    let payload: [String: Any] = [
      CastJSONPayloadKeys.type: CastMessageType.availableApps.rawValue,
      CastJSONPayloadKeys.appId: apps.map { $0.id }
    ]
    
    let request = requestDispatcher.request(withNamespace: namespace,
                                       destinationId: CastConstants.receiver,
                                       payload: payload)
    
    send(request) { result in
      switch result {
      case .success(let json):
        completion(Result(value: AppAvailability(json: json)))
      case .failure(let error):
        completion(Result(error: CastError.launch(error.localizedDescription)))
      }
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
  
  func launch(appId: String, completion: @escaping (Result<CastApp, CastError>) -> Void) {
    let payload: [String: Any] = [
      CastJSONPayloadKeys.type: CastMessageType.launch.rawValue,
      CastJSONPayloadKeys.appId: appId
    ]
    
    let request = requestDispatcher.request(withNamespace: namespace,
                                       destinationId: CastConstants.receiver,
                                       payload: payload)
    
    send(request) { result in
      switch result {
      case .success(let json):
        guard let app = CastStatus(json: json).apps.first else {
          completion(Result(error: CastError.launch("Unable to get launched app instance")))
          return
        }
        
        completion(Result(value: app))
        
      case .failure(let error):
        completion(Result(error: error))
      }
      
    }
  }
  
  public func stop(app: CastApp) {
    let payload: [String: Any] = [
      CastJSONPayloadKeys.type: CastMessageType.stop.rawValue,
      CastJSONPayloadKeys.sessionId: app.sessionId
    ]
    
    let request = requestDispatcher.request(withNamespace: namespace,
                                       destinationId: CastConstants.receiver,
                                       payload: payload)
    
    send(request)
  }
  
  public func setVolume(_ volume: Float) {
    let payload: [String: Any] = [
      CastJSONPayloadKeys.type: CastMessageType.setVolume.rawValue,
      CastJSONPayloadKeys.volume: [CastJSONPayloadKeys.level: volume]
    ]
    
    let request = requestDispatcher.request(withNamespace: namespace,
                                 destinationId: CastConstants.receiver,
                                 payload: payload)
    
    send(request)
  }
  
  public func setMuted(_ isMuted: Bool) {
    let payload: [String: Any] = [
      CastJSONPayloadKeys.type: CastMessageType.setVolume.rawValue,
      CastJSONPayloadKeys.volume: [CastJSONPayloadKeys.muted: isMuted]
    ]
    
    let request = requestDispatcher.request(withNamespace: namespace,
                                 destinationId: CastConstants.receiver,
                                 payload: payload)
    
    send(request)
  }
}

protocol ReceiverControlChannelDelegate: RequestDispatchable {
  func channel(_ channel: ReceiverControlChannel, didReceive status: CastStatus)
}
