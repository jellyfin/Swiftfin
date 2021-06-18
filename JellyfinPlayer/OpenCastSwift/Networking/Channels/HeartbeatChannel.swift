//
//  CastHeartbeatChannel.swift
//  OpenCastSwift
//
//  Created by Miles Hollingsworth on 4/22/18
//  Copyright © 2018 Miles Hollingsworth. All rights reserved.
//

import Foundation
import SwiftyJSON

class HeartbeatChannel: CastChannel {
  private lazy var timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(sendPing), userInfo: nil, repeats: true)

  private let disconnectTimeout: TimeInterval = 10
  private var disconnectTimer: Timer? {
    willSet {
      disconnectTimer?.invalidate()
    }
    didSet {
      guard let timer = disconnectTimer else { return }

        RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
    }
  }

  override weak var requestDispatcher: RequestDispatchable! {
    didSet {
      if let _ = requestDispatcher {
        startBeating()
      } else {
        timer.invalidate()
      }
    }
  }

  private var delegate: HeartbeatChannelDelegate? {
    return requestDispatcher as? HeartbeatChannelDelegate
  }

  init() {
    super.init(namespace: CastNamespace.heartbeat)
  }

  override func handleResponse(_ json: JSON, sourceId: String) {
    delegate?.channelDidConnect(self)

    guard let rawType = json["type"].string else { return }

    guard let type = CastMessageType(rawValue: rawType) else {
      print("Unknown type: \(rawType)")
      print(json)
      return
    }

    if type == .ping {
      sendPong(to: sourceId)
      print("PING from \(sourceId)")
    }

    disconnectTimer = Timer(timeInterval: disconnectTimeout,
                            target: self,
                            selector: #selector(handleTimeout),
                            userInfo: nil,
                            repeats: false)
  }

  private func startBeating() {
    _ = timer
    sendPing()
  }

  @objc private func sendPing() {
    let request = requestDispatcher.request(withNamespace: namespace,
                                       destinationId: CastConstants.transport,
                                       payload: [CastJSONPayloadKeys.type: CastMessageType.ping.rawValue])

    send(request)
  }

  private func sendPong(to destinationId: String) {
    let request = requestDispatcher.request(withNamespace: namespace,
                                 destinationId: destinationId,
                                 payload: [CastJSONPayloadKeys.type: CastMessageType.pong.rawValue])

    send(request)
  }

  @objc private func handleTimeout() {
    delegate?.channelDidTimeout(self)
  }
}

protocol HeartbeatChannelDelegate: AnyObject {
  func channelDidConnect(_ channel: HeartbeatChannel)
  func channelDidTimeout(_ channel: HeartbeatChannel)
}
