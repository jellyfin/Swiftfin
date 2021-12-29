//
//  PlayerOverlayDelegate.swift
//  JellyfinVideoPlayerDev
//
//  Created by Ethan Pippin on 12/27/21.
//

import Foundation

protocol PlayerOverlayDelegate {
    
    func didSelectClose()
    func didSelectGoogleCast()
    func didSelectAirplay()
    func didSelectCaptions()
    func didSelectMenu()
    func didDeselectMenu()
    
    func didSelectBackward()
    func didSelectForward()
    func didSelectMain()
    
    func didGenerallyTap()
    
    func didBeginScrubbing()
    func didEndScrubbing(position: Double)
    
    func didSelectAudioStream(index: Int)
    func didSelectSubtitleStream(index: Int)
    
    func didSelectPreviousItem()
    func didSelectNextItem()
}
