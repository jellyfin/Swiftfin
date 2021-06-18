//
//  DeviceAuthChannel.swift
//  OpenCastSwift Mac
//
//  Created by Miles Hollingsworth on 4/22/18
//  Copyright © 2018 Miles Hollingsworth. All rights reserved.
//

import Foundation

class DeviceAuthChannel: CastChannel {
  typealias CastAuthChallenge = Extensions_Api_CastChannel_AuthChallenge
  typealias CastAuthMessage = Extensions_Api_CastChannel_DeviceAuthMessage
  
  init() {
    super.init(namespace: CastNamespace.auth)
  }
  
  public func sendAuthChallenge() throws {
    let message = CastAuthMessage.with {
      $0.challenge = CastAuthChallenge()
    }
    
    let request = requestDispatcher.request(withNamespace: namespace,
                                       destinationId: CastConstants.receiver,
                                       payload: try message.serializedData())

    send(request)
  }
}
