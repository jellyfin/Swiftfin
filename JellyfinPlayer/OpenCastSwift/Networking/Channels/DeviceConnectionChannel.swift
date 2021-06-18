//
//  DeviceConnectionChannel.swift
//  OpenCastSwift Mac
//
//  Created by Miles Hollingsworth on 4/22/18
//  Copyright © 2018 Miles Hollingsworth. All rights reserved.
//

import Foundation

class DeviceConnectionChannel: CastChannel {
  override weak var requestDispatcher: RequestDispatchable! {
    didSet {
      if let _ = requestDispatcher {
        connect()
      }
    }
  }
  
  init() {
    super.init(namespace: CastNamespace.connection)
  }
  
  func connect() {
    let request = requestDispatcher.request(withNamespace: namespace,
                                 destinationId: CastConstants.receiver,
                                 payload: [CastJSONPayloadKeys.type: CastMessageType.connect.rawValue])
    
    send(request)
  }
  
  func connect(to app: CastApp) {
    let request = requestDispatcher.request(withNamespace: namespace,
                                 destinationId: app.transportId,
                                 payload: [CastJSONPayloadKeys.type: CastMessageType.connect.rawValue])
    
    send(request)
  }
  
  public func leave(_ app: CastApp) {
    let request = requestDispatcher.request(withNamespace: namespace,
                                 destinationId: app.transportId,
                                 payload: [CastJSONPayloadKeys.type: CastMessageType.close.rawValue])
    
    send(request)
  }
}
