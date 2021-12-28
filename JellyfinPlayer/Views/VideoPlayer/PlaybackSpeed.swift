//
//  PlaybackSpeed.swift
//  JellyfinVideoPlayerDev
//
//  Created by Ethan Pippin on 12/27/21.
//

import Foundation

enum PlaybackSpeed: Double, CaseIterable {
    case quarter = 0.25
    case half = 0.5
    case threeQuarter = 0.75
    case one = 1.0
    case oneQuarter = 1.25
    case oneHalf = 1.5
    case oneThreeQuarter = 1.75
    case two = 2.0
    
    var displayTitle: String {
        switch self {
        case .quarter:
            return "0.25x"
        case .half:
            return "0.5x"
        case .threeQuarter:
            return "0.75x"
        case .one:
            return "1x"
        case .oneQuarter:
            return "1.25x"
        case .oneHalf:
            return "1.5x"
        case .oneThreeQuarter:
            return "1.75x"
        case .two:
            return "2x"
        }
    }
}
