//
//  CastMedia.swift
//  OpenCastSwift
//
//  Created by Miles Hollingsworth on 4/22/18
//  Copyright © 2018 Miles Hollingsworth. All rights reserved.
//

import Foundation

public let CastMediaStreamTypeBuffered = "BUFFERED"
public let CastMediaStreamTypeLive = "LIVE"

public enum CastMediaStreamType: String {
    case buffered = "BUFFERED"
    case live = "LIVE"
}

public final class CastMedia: NSObject {
    public let title: String
    public let url: URL
    public let poster: URL?
    
    public let autoplay: Bool
    public let currentTime: Double
    
    public let contentType: String
    public let streamType: CastMediaStreamType
    
    public init(title: String, url: URL, poster: URL? = nil, contentType: String, streamType: CastMediaStreamType = .buffered, autoplay: Bool = true, currentTime: Double = 0) {
        self.title = title
        self.url = url
        self.poster = poster
        self.contentType = contentType
        self.streamType = streamType
        self.autoplay = autoplay
        self.currentTime = currentTime
    }
    
//    public convenience init(title: String, url: URL, poster: URL, contentType: String, streamType: String, autoplay: Bool, currentTime: Double) {
//        guard let type = CastMediaStreamType(rawValue: streamType) else {
//            fatalError("Invalid media stream type \(streamType)")
//        }
//      
//        self.init(title: title, url: url, poster: poster, contentType: contentType, streamType: type, autoplay: autoplay, currentTime: currentTime)
//    }
}

extension CastMedia {
    
    var dict: [String: Any] {
      if let poster = poster {
        return [
          CastJSONPayloadKeys.autoplay: autoplay,
          CastJSONPayloadKeys.activeTrackIds: [],
          CastJSONPayloadKeys.repeatMode: "REPEAT_OFF",
          CastJSONPayloadKeys.currentTime: currentTime,
          CastJSONPayloadKeys.media: [
            CastJSONPayloadKeys.contentId: url.absoluteString,
            CastJSONPayloadKeys.contentType: contentType,
            CastJSONPayloadKeys.streamType: streamType.rawValue,
            CastJSONPayloadKeys.metadata: [
              CastJSONPayloadKeys.type: 0,
              CastJSONPayloadKeys.metadataType: 0,
              CastJSONPayloadKeys.title: title,
              CastJSONPayloadKeys.images: [
                [CastJSONPayloadKeys.url: poster.absoluteString]
              ]
            ]
          ]
        ]
      } else {
        return [
          CastJSONPayloadKeys.autoplay: autoplay,
          CastJSONPayloadKeys.activeTrackIds: [],
          CastJSONPayloadKeys.repeatMode: "REPEAT_OFF",
          CastJSONPayloadKeys.currentTime: currentTime,
          CastJSONPayloadKeys.media: [
            CastJSONPayloadKeys.contentId: url.absoluteString,
            CastJSONPayloadKeys.contentType: contentType,
            CastJSONPayloadKeys.streamType: streamType.rawValue,
            CastJSONPayloadKeys.metadata: [
              CastJSONPayloadKeys.type: 0,
              CastJSONPayloadKeys.metadataType: 0,
              CastJSONPayloadKeys.title: title
            ]
          ]
        ]
      }
    }
    
}
