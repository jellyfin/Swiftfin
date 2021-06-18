//
//  AppAvailability.swift
//  OpenCastSwift
//
//  Created by Miles Hollingsworth on 4/22/18
//  Copyright © 2018 Miles Hollingsworth. All rights reserved.
//

import SwiftyJSON
import Foundation

public class AppAvailability: NSObject {
  public var availability = [String: Bool]()
}

extension AppAvailability {
  convenience init(json: JSON) {
    self.init()
    
    if let availability = json[CastJSONPayloadKeys.availability].dictionaryObject as? [String: String] {
      self.availability = availability.mapValues { $0 == "APP_AVAILABLE" }
    }
  }
}
