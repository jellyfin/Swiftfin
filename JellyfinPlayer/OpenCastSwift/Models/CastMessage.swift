//
//  CastMessage.swift
//  OpenCastSwift
//
//  Created by Miles Hollingsworth on 4/22/18
//  Copyright © 2018 Miles Hollingsworth. All rights reserved.
//

import Foundation

extension CastMessage {
  static func encodedMessage(payload: CastPayload, namespace: String, sourceId: String, destinationId: String) throws -> Data {
    var message = CastMessage()
    message.protocolVersion = .castv210
    message.sourceID = sourceId
    message.destinationID = destinationId
    message.namespace = namespace
    
    switch payload {
    case .json(let payload):
      let json = try JSONSerialization.data(withJSONObject: payload, options: [])
      
      guard let jsonString = String(data: json, encoding: .utf8) else {
        fatalError("error forming json string")
      }
      
      message.payloadType = .string
      message.payloadUtf8 = jsonString
    case .data(let payload):
      message.payloadType = .binary
      message.payloadBinary = payload
    }
    
    return try message.serializedData()
  }
}
